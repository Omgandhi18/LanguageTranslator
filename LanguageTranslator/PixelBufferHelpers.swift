//
//  PixelBufferHelpers.swift
//  LanguageTranslator
//
//  Created by Om Gandhi on 03/06/2024.
//

import Foundation
import Accelerate
import CoreImage


/// Crops the pixel buffer.
public func resizePixelBuffer(
  _ srcPixelBuffer: CVPixelBuffer,
  cropX: Int,
  cropY: Int,
  cropWidth: Int,
  cropHeight: Int
) -> CVPixelBuffer? {
  let flags = CVPixelBufferLockFlags(rawValue: 0)
  guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(srcPixelBuffer, flags) else {
    return nil
  }
  defer { CVPixelBufferUnlockBaseAddress(srcPixelBuffer, flags) }

  guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
    print("Error: could not get pixel buffer base address")
    return nil
  }
  let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
  let offset = cropY * srcBytesPerRow + cropX * 4
  var srcBuffer = vImage_Buffer(
    data: srcData.advanced(by: offset),
    height: vImagePixelCount(cropHeight),
    width: vImagePixelCount(cropWidth),
    rowBytes: srcBytesPerRow)

  let destBytesPerRow = cropWidth * 4
  guard let destData = malloc(cropHeight * destBytesPerRow) else {
    print("Error: out of memory")
    return nil
  }
  var destBuffer = vImage_Buffer(
    data: destData,
    height: vImagePixelCount(cropHeight),
    width: vImagePixelCount(cropWidth),
    rowBytes: destBytesPerRow)

  let error = vImageCopyBuffer(&srcBuffer, &destBuffer, 4, vImage_Flags(0))
  if error != kvImageNoError {
    print("Error:", error)
    free(destData)
    return nil
  }

  let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
    if let ptr = ptr {
      free(UnsafeMutableRawPointer(mutating: ptr))
    }
  }

  let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
  var dstPixelBuffer: CVPixelBuffer?
  let status = CVPixelBufferCreateWithBytes(
    nil, cropWidth, cropHeight,
    pixelFormat, destData,
    destBytesPerRow, releaseCallback,
    nil, nil, &dstPixelBuffer)
  if status != kCVReturnSuccess {
    print("Error: could not create new pixel buffer")
    free(destData)
    return nil
  }
  return dstPixelBuffer
}

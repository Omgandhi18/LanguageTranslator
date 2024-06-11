//
//  HomeVC.swift
//  LanguageTranslator
//
//  Created by Om Gandhi on 11/06/2024.
//

import UIKit
import MLKit
import MaterialComponents

class HomeVC: UIViewController {

    @IBOutlet weak var txtFirstLang: UITextField!
    @IBOutlet weak var txtSecLang: UITextField!
    @IBOutlet weak var txtText1: UITextView!
    @IBOutlet weak var txtText2: UITextView!
    
    
    
    var selectedTextField = UITextField()
    var firstLang = TranslateLanguage.english
    var secondLang = TranslateLanguage.english
    var translator: Translator!
    private let languageArr = [TranslateLanguage.afrikaans,TranslateLanguage.albanian,TranslateLanguage.arabic,TranslateLanguage.belarusian,TranslateLanguage.bengali,TranslateLanguage.bulgarian,TranslateLanguage.catalan,TranslateLanguage.chinese,TranslateLanguage.croatian,TranslateLanguage.czech,TranslateLanguage.danish,TranslateLanguage.dutch,TranslateLanguage.english,TranslateLanguage.eperanto,TranslateLanguage.estonian,TranslateLanguage.finnish,TranslateLanguage.french,TranslateLanguage.galician,TranslateLanguage.georgian,TranslateLanguage.german,TranslateLanguage.greek,TranslateLanguage.gujarati,TranslateLanguage.haitianCreole,TranslateLanguage.hebrew,TranslateLanguage.hindi,TranslateLanguage.hungarian,TranslateLanguage.icelandic,TranslateLanguage.indonesian,TranslateLanguage.irish,TranslateLanguage.irish,TranslateLanguage.italian,TranslateLanguage.japanese,TranslateLanguage.korean,TranslateLanguage.latvian,TranslateLanguage.lithuanian,TranslateLanguage.macedonian,TranslateLanguage.malay,TranslateLanguage.maltese,TranslateLanguage.marathi,TranslateLanguage.norwegian,TranslateLanguage.persian,TranslateLanguage.polish,TranslateLanguage.portuguese,TranslateLanguage.romanian,TranslateLanguage.russian,TranslateLanguage.slovak,TranslateLanguage.slovenian,TranslateLanguage.spanish,TranslateLanguage.swahili,TranslateLanguage.swedish,TranslateLanguage.tagalog,TranslateLanguage.tamil,TranslateLanguage.telugu,TranslateLanguage.thai,TranslateLanguage.turkish,TranslateLanguage.ukrainian,TranslateLanguage.urdu,TranslateLanguage.vietnamese,TranslateLanguage.welsh]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.txtText1.layer.cornerRadius = 10
        self.txtText1.layer.borderColor = UIColor.gray.cgColor
        self.txtText1.layer.borderWidth = 1.0;
        
        self.txtText2.layer.cornerRadius = 10
        self.txtText2.layer.borderColor = UIColor.gray.cgColor
        self.txtText2.layer.borderWidth = 1.0;
        
        txtFirstLang.text = TranslateLanguage.english.localizedName()
        txtSecLang.text = TranslateLanguage.english.localizedName()
        txtText2.isUserInteractionEnabled = false
    }
    
    @IBAction func btnOpenCamera(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "cameraStory") as! CameraVC
        vc.modalTransitionStyle = .flipHorizontal
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

extension HomeVC: UITextFieldDelegate,UITextViewDelegate,UIPickerViewDelegate,UIPickerViewDataSource{
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == txtFirstLang{
            selectedTextField = txtFirstLang
        }
        else if textField == txtSecLang{
            selectedTextField = txtSecLang
        }
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 200))
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.dismissAction))
        toolBar.setItems([button], animated: true)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
       
        textField.inputView = pickerView
        return true
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languageArr.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languageArr[row].localizedName()
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if selectedTextField == txtFirstLang{
            firstLang = languageArr[row]
            txtFirstLang.text = languageArr[row].localizedName()
        }
        else if selectedTextField == txtSecLang{
            secondLang = languageArr[row]
            txtSecLang.text = languageArr[row].localizedName()
        }
        
        
    }
    @objc func dismissAction() {
        translate(txtText1.text ?? "")
        view.endEditing(true)
    }
    func textViewDidChange(_ textView: UITextView) {
        translate(txtText1.text)
    }
    
    func translate(_ inputText: String) {
        //MARK: Insert language selected option
        let options = TranslatorOptions(
          sourceLanguage: firstLang,
          targetLanguage: secondLang)
        translator = Translator.translator(options: options)
        self.txtText2.text = "Processing"
        let translatorForDownloading = self.translator!
        translatorForDownloading.downloadModelIfNeeded { error in
          guard error == nil else {
            print("Failed to ensure model downloaded with error \(error!)")
            return
          }
          if translatorForDownloading == self.translator {
            translatorForDownloading.translate(inputText) { result, error in
              guard error == nil else {
                print("Failed with error \(error!)")
                  self.txtText2.text = ""
                return
              }
              if translatorForDownloading == self.translator {
                DispatchQueue.main.async {
                  self.txtText2.text = result
                }
              }
            }
          }
        }
      }
}

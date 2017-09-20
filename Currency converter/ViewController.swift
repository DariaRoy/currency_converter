//
//  ViewController.swift
//  Currency converter
//
//  Created by Air on 14.09.17.
//  Copyright © 2017 Dasha. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var buttonSwap: UIButton!
    
    @IBOutlet weak var fromTextField: UITextField! {
        didSet {
            let myColor: UIColor = UIColor.gray
            fromTextField.layer.borderWidth = 1
            fromTextField.layer.borderColor = myColor.cgColor
        }
    }
    
    @IBOutlet weak var pickFrom: UIPickerView!
    @IBOutlet weak var pickTo: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var currencyRate: String = " " {
        didSet {
            self.fromTextField.text = "1"
            self.label.text = currencyRate
            self.activityIndicator.stopAnimating()
        }
    }
    
    var currencies = [String]()
    
    @IBAction func changeCurrencyRate(_ sender: UIButton) {
        let baseCurrencyIndex = self.pickFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickTo.selectedRow(inComponent: 0)
        
        let baseCurrency = currencies[baseCurrencyIndex]
        let toCurrency = currenciesExceptBase()[toCurrencyIndex]
        
        let to = currencies.index(of: toCurrency)
        self.pickFrom.selectRow(to!, inComponent: 0, animated: true)
        self.pickTo.reloadAllComponents()

        
        let base = currenciesExceptBase().index(of: baseCurrency)
        self.pickTo.selectRow(base!, inComponent: 0, animated: true)
        
        self.requestCurrentCurrencyRate()
    }
    
    func retrieveCurrency() -> [String] {
        var string = [String]()
        let url = URL(string: "https://api.fixer.io/latest")!
        let urlContents = try? Data(contentsOf: url)
        if let json = urlContents {
            string = parseCurrencyResponse(data: json)
        }
        
        return string
    }
    
    func parseCurrencyResponse(data: Data?) -> [String] {
        var currencies = [String]()
        if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any> {
            if let parsedJSON = json {
                //print("\(parsedJSON)")
                currencies.append(parsedJSON["base"] as! String)
                if let rates =  parsedJSON["rates"] as? Dictionary<String, Double> {
                    for (name, _) in rates {
                        currencies.append(name)
                    }
                }
            }
        }
        return currencies
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currencies = retrieveCurrency()
        if  currencies == [] {
            let labelRect = CGRect(x: view.bounds.midX - 60 , y: view.bounds.midY - 50, width: 150, height: 50)
            let newLabel = UILabel(frame: labelRect)
            newLabel.text = "No connection"
            view.addSubview(newLabel)
            
            self.label.isHidden = true
            self.activityIndicator.isHidden = true
            self.pickTo.isHidden = true
            self.pickFrom.isHidden = true
            self.fromTextField.isHidden = true
            self.buttonSwap.isHidden = true
            return
        }
        
        self.fromTextField.delegate = self
        
        self.pickTo.dataSource = self
        self.pickFrom.dataSource = self
        
        self.pickTo.delegate = self
        self.pickFrom.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        self.requestCurrentCurrencyRate()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func requestCurrencyRates(baseCurrency: String, parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        dataTask.resume()
    }
    
    func requestCurrentCurrencyRate() {
        
        self.activityIndicator.startAnimating()
        self.label.text = " "
        
        let baseCurrencyIndex = self.pickFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) { [weak self] (value) in
            DispatchQueue.main.async(execute: {
                if let strongSelf = self {
                    strongSelf.currencyRate = value
                    //strongSelf.label.text = value
                    //strongSelf.activityIndicator.stopAnimating()
                }
            })
        }
    }
    
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value: String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates =  parsedJSON["rates"] as? Dictionary<String, Double> {
                    if let rate = rates[toCurrency] {
                        value = "\(rate)"
                    } else {
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"rates\" field found"
                }
            } else{
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        return value
    }
    
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completion: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) { [weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            completion(string)
        }
    }
    
    
    func currenciesExceptBase() -> [String] {
        var currenciesExceptBase = currencies
        currenciesExceptBase.remove(at: pickFrom.selectedRow(inComponent: 0))
        
        return currenciesExceptBase
    }

    //MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === pickTo {
            return self.currenciesExceptBase().count
        }
        return currencies.count
    }
    
    //MARK: - UIPickerDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickTo {
            return self.currenciesExceptBase()[row]
        }
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickFrom {
            self.pickTo.reloadAllComponents()
        }
        
        self.requestCurrentCurrencyRate()
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        fromTextField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var text = fromTextField.text ?? ""
        if text == "" {
            fromTextField.text = "1"
            text = "1"
        }
        if let number = Double(text), let curRate = Double(currencyRate) {
            label.text = String(curRate * number)
        }
    }
    
}


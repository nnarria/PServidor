//
//  ViewController.swift
//  PServidor
//
//  Created by Nicolás Narria on 1/24/16.
//  Copyright © 2016 Nicolás Narria. All rights reserved.
//

import UIKit
import SystemConfiguration

class ViewController: UIViewController, UISearchBarDelegate, UITextFieldDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    var urlServicio: String = ""
    
    var overlayView: UIView!
    var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var portada: UIImageView!

    @IBOutlet weak var listaAutores: UITextView!
    @IBOutlet weak var tituloLibro: UITextView!
    
    @IBOutlet weak var titAutores: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        
        self.urlServicio = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:"
        
        
        
        /* Para mostrar indicador de actividad cargando */
        loadingIndicator = UIActivityIndicatorView(frame: CGRectMake(10, 5, 50, 50)) as UIActivityIndicatorView
        overlayView = UIView()
        overlayView.frame = CGRectMake(0, 0, 80, 80)
        overlayView.backgroundColor = UIColor(white: 0, alpha:0.7)
        overlayView.clipsToBounds = true
        overlayView.layer.cornerRadius = 10
        overlayView.layer.zPosition = 1
        
        loadingIndicator.frame = CGRectMake (0, 0, 40, 40)
        loadingIndicator.center = CGPointMake (overlayView.bounds.width / 2, overlayView.bounds.height / 2)
        loadingIndicator.activityIndicatorViewStyle = .WhiteLarge
        overlayView.addSubview(loadingIndicator)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        print ("ahora si: \(searchBar.text!)")
        
        if (isConnectedToNetwork() == false) {
            let alertController = UIAlertController(title: "Conexión a internet perdida", message: "Debe conectarse a Internet", preferredStyle: UIAlertControllerStyle.Alert)
            
            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
            
            self.presentViewController (alertController, animated: true, completion: nil)
        }
        else {
            
            //eliminar espacios en blanco al inicio y al final del texto ingresado
            let isbn = searchBar.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let url = NSURL(string: urlServicio + isbn)

            /* sincrono */
            /*
            let datos:NSData? = NSData(contentsOfURL: url!)
            let texto = NSString(data: datos!, encoding: NSUTF8StringEncoding)
        
            outputTex.text = String(texto!)
        
            print("pp: \(texto!) url: \(urlServicio)")
            */
            

            
            /* asincrono */
            let sesion = NSURLSession.sharedSession()
            let bloque = { (datos: NSData?, resp: NSURLResponse?, error: NSError?) -> Void in
                _ = NSString(data: datos!, encoding: NSUTF8StringEncoding)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.loadingIndicator.stopAnimating()
                    self.overlayView.removeFromSuperview()
                    
                    
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(datos!, options: NSJSONReadingOptions.MutableLeaves)
                        let dico1 = json as! NSDictionary
                        
                        if (dico1["ISBN:"+isbn] != nil) {
                        
                            let dico2 = dico1["ISBN:"+isbn] as! NSDictionary
                            let lstAuthors = dico2["authors"] as! NSArray
                            let bookName = dico2["title"] as! NSString as String
                        
                            self.portada.image = nil
                        
                            if (dico2["cover"] != nil) {
                                let dicoCover = dico2["cover"] as! NSDictionary
                                let urls = dicoCover["medium"] as! NSString as String
                            
                                let url = NSURL(string:urls)
                                let datos = NSData(contentsOfURL: url!)
                                let img = UIImage (data: datos!)
                                self.portada.image = img
                            
                                //print ("Cover:" + urls)
                            }
                        
                            self.tituloLibro.text = bookName
                            //print ("titulo: " + bookName)
                        
                        
                        
                            self.titAutores.text = String(lstAuthors.count)  + " Autor(es)"
                        
                            var aux: String = ""
                            var i: Int = 1
                            for element in lstAuthors {
                                let dicoAuthor = element as! NSDictionary
                                let nombre = dicoAuthor["name"] as! NSString as String
                            
                                aux += String(i) + " - " + nombre + "\n"
                            
                                i++
                                //ok
                                //print("nombre author: " + nombre)
                            }
                            self.listaAutores.text = aux
                        }
                        else {
                            self.portada.image = nil
                            self.tituloLibro.text = ""
                            self.titAutores.text = "Autor(es)"
                            self.listaAutores.text = ""
                        }
                        
                    }
                    catch _ {
                        
                    }
                }
                
                
                //print ("\(texto!)")
                
                if (error != nil) {
                    let alertController = UIAlertController(title: "Error de comunicación", message: "Vuelva a intentar", preferredStyle: UIAlertControllerStyle.Alert)
                    
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
                    
                    self.presentViewController (alertController, animated: true, completion: nil)
                }
                
            }
            
            
            let dt = sesion.dataTaskWithURL(url!, completionHandler: bloque)

            overlayView.center = self.view.center
            self.view.addSubview(overlayView)
            
            /* muestra mensaje de cargando */
            loadingIndicator.startAnimating()
            
            dt.resume()
            
        }
        
        
        view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    
    // se ejecuta cada vez que se presiona una tecla del teclado
    func searchBar (searchBar: UISearchBar, textDidChange searchText: String) {
        print("Quieres buscar: \(searchText)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func userTappedBackground(sender: AnyObject) {
        view.endEditing(true)
    }
    
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    
 
    
    /* verificar conexion a internet */
    func isConnectedToNetwork () -> Bool {
        var zeroAddress = sockaddr_in () // se crea un socket tipo in
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer (&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress (nil, UnsafePointer($0))
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection)
    }


}


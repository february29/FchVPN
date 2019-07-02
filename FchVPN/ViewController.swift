//
//  ViewController.swift
//  FchVPN
//
//  Created by bai on 2018/3/19.
//  Copyright © 2018年 北京仙指信息技术有限公司. All rights reserved.
//

import UIKit
import NetworkExtension
//import OpenVPNAdapter

@available(iOS 9.0, *)
class ViewController: UIViewController {
    
    var providerManager:NETunnelProviderManager?
    
    
    let btn = UIButton();
    let loginbtn = UIButton();
    
//    lazy var vpnAdapter: OpenVPNAdapter = {
//        let adapter = OpenVPNAdapter()
////        adapter.delegate = self
//
//        return adapter
//    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 40);
        btn.backgroundColor = .green;
        self.view.addSubview(btn);
        btn.addTarget(self, action: #selector(startVPN), for: .touchUpInside);
        
        
        self .confingVPN();
        
        
//        self.networktest();
        
        loginbtn.frame = CGRect(x: 100, y: 200, width: 100, height: 40);
        loginbtn.backgroundColor = .blue;
        self.view.addSubview(loginbtn);
        loginbtn.addTarget(self, action: #selector(networktest), for: .touchUpInside);
        
        
    }
    
    
    @objc func startVPN()  {
        
        
        
        self.providerManager?.loadFromPreferences(completionHandler: { (error) in
            guard error == nil else {
                // Handle an occured error
                print("loadFromPreferences error \(String(describing: error))")
                return
            }
            
            do {
                try self.providerManager?.connection.startVPNTunnel()
                
//                self.providerManager?.connection.startVPNTunnel(options: ["username":username,"password":password])
                self .addVPNStatusObserver();
                print("startVPNTunnel state \(String(describing: self.providerManager?.connection.status))")
                
            } catch {
                // Handle an occured error
                print("startVPNTunnel error \(String(describing: error))")
            }
        })
        
        
        
       
    }
    
    /// 添加vpn的状态的监听
    func addVPNStatusObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: self.providerManager?.connection.status, queue: OperationQueue.main, using: { [unowned self] (notification) -> Void in
            
            
            if self.providerManager?.connection.status == .invalid{
                print("/*! @const NEVPNStatusInvalid The VPN is not configured. */")
            }else if self.providerManager?.connection.status == .disconnected{
                print("disconnected");
            }else if self.providerManager?.connection.status == .connecting{
                print("connecting");
            }else if self.providerManager?.connection.status == .connected{
                print("connected");
            }else if self.providerManager?.connection.status == .reasserting{
                print("reasserting");
            }else if self.providerManager?.connection.status == .disconnecting{
                print("disconnecting");
            }else{
                print("error");
            }
            
        })
    }
    
    
    
    func confingVPN()  {
        //获取VPNManager
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            guard error == nil else {
                // Handle an occured error
                print("loadAllFromPreferences error \(String(describing: error))")
                return
            }
            
            self.providerManager = managers?.first ?? NETunnelProviderManager()
            
            
            //配置VPN
            self.providerManager?.loadFromPreferences(completionHandler: { (error) in
                guard error == nil else {
                    // Handle an occured error
                    print("loadFromPreferences error")
                    return
                }
                
                // Assuming the app bundle contains a configuration file named 'client.ovpn' lets get its
                // Data representation
                
                guard
                    let configurationFileURL = Bundle.main.url(forResource: "client2", withExtension: "ovpn"),
                    let configurationFileContent = try? Data(contentsOf: configurationFileURL)
                    else {
                        fatalError()
                }
                
                let tunnelProtocol = NETunnelProviderProtocol()
                
                // If the ovpn file doesn't contain server address you can use this property
                // to provide it. Or just set an empty string value because `serverAddress`
                // property must be set to a non-nil string in either case.
                tunnelProtocol.serverAddress = "223.100.8.226 11194"
                
                // The most important field which MUST be the bundle ID of our custom network
                // extension target.
                tunnelProtocol.providerBundleIdentifier = "com.xianzhi.www.FchVPN.FchVPNPacketTunnel"
                
                // Use `providerConfiguration` to save content of the ovpn file.
                tunnelProtocol.providerConfiguration = ["ovpn": configurationFileContent]
                
                // Provide user credentials if needed. It is highly recommended to use
                // keychain to store a password.
//                tunnelProtocol.username = "username"
//                tunnelProtocol.passwordReference = Data()  // A persistent keychain reference to an item containing the password
                
                // Finish configuration by assigning tunnel protocol to `protocolConfiguration`
                // property of `providerManager` and by setting description.
                self.providerManager?.protocolConfiguration = tunnelProtocol
                self.providerManager?.localizedDescription = "Fch OpenVPN Client"
                
                self.providerManager?.isEnabled = true
                
                // Save configuration in the Network Extension preferences
                self.providerManager?.saveToPreferences(completionHandler: { (error) in
                    if let error = error  {
                        // Handle an occured error
                        print("saveToPreferences error \(String(describing: error)) ")
                    }
                })
//                self.providerManager?.removeFromPreferences(completionHandler: { (error) in
//                    
//                })
               
                
            })
            
        }
        
        
        
        
    
    }
    
    
    @objc func networktest(){
    
    
    //1. 创建一个网络请求
    let url = URL.init(string: "http://10.32.112.164/logout")
    
    //2.创建请求对象
    let request = URLRequest.init(url: url!);
    
    //3.获得会话对象
    let session=URLSession.shared;
    
    //4.根据会话对象创建一个Task(发送请求）
    /*
     第一个参数：请求对象
     第二个参数：completionHandler回调（请求完成【成功|失败】的回调）
     data：响应体信息（期望的数据）
     response：响应头信息，主要是对服务器端的描述
     error：错误信息，如果请求失败，则error有值
     */
    
    let dataTask = session.dataTask(with: request) { (data, respon, error) in
        print(respon ?? "eee");
    };
    dataTask.resume();
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


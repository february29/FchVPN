# FchVPN
ios openvpn demo


**注意**

1. demo工程可能因为swift版本、第三方库等因素无法编译通过。
2. demo中现有的服务器现已关闭，无法连接。

**详细说明**

[ios OpenVPN 使用](https://www.jianshu.com/p/66039ea97656)


## 实现方式
NetWorkExtension + OpenVPNAdapter.

NetWorkExtension主要帮助我们完成VPN的配置与获取配置信息。OpenVPNAdapter帮我们建立连接。

[demo 传送们](https://github.com/february29/FchVPN)
**注意：**demo仅供参考，demo所用服务器已关闭，demo可能因为swfit版本与第三方库等原因无法编译通过。

### NetWorkExtension
[NetWorkExtension](https://developer.apple.com/documentation/networkextension) App拓展。

#### 创建NetWorkExtension
1. 创建NetWorkExtension target。
2. 开启相关权限。
3. 配置VPN到手机。

##### NetWorkExtension Target创建

![61C716C6-2116-405C-843D-C4ADA12F1D52.png](https://upload-images.jianshu.io/upload_images/5873462-812a77640cd52353.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![B9597FB0-4976-4704-95C8-88D631EAB7E7.png](https://upload-images.jianshu.io/upload_images/5873462-8ab45ff3aea26753.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


![11B9489C-91F6-4339-A8DC-74106AA03026.png](https://upload-images.jianshu.io/upload_images/5873462-3b2bae108cb114c1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


##### 权限配置
权限配置需要在宿主app与app extension都配置完成。

![D4159E5A-B09C-48AA-AA56-949C43338CD0.png](https://upload-images.jianshu.io/upload_images/5873462-ae019406e98d5bd7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

权限配置完毕后会在鉴权文件中显示。
![8E5AA5B6-187E-4CE2-9540-177E333D2B83.png](https://upload-images.jianshu.io/upload_images/5873462-fe5f3de0aad770e0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


如若涉及到宿主app与app extension之间的通讯，利用app groups。同样宿主app、app extension都需要打开并配置相同的app group
![9D017D88-7D2F-475B-90F3-6B13A4E3B45D.png](https://upload-images.jianshu.io/upload_images/5873462-a4f4345bc36e4138.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


##### 配置VPN到手机

宿主app引入NetWorkExtension框架，通过NetWorkExtension框架下提供的API  将openVPN的配置信息配置到手机。



代码如下：

```
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
                tunnelProtocol.providerBundleIdentifier = "app extension的bundle identifier "
                
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

```
可以看到配置过程主要就是两个过程：
1. 建立NETunnelProviderProtocol
2. 利用NETunnelProviderManager将NETunnelProviderProtocol保存到手机。

 NETunnelProviderProtocol继承自NEVPNProtocol, NEVPNProtocol提供了其他的一些建立连接常用和必须参数需要我们配置，我们可以在这里用代码配置一些NEVPNProtocol提供的配置信息，比如用户名密码等。NETunnelProviderProtocol在NEVPNProtocol基础上拓展了providerConfigurationg 方便我们从外部文件（.ovpn）中获取配置信息。

-NETunnelProviderProtocol会在我们调用开启连接时完全的传递到我们的appextension当中。我们可以在app extension中通过以下方式获取配置信息
```
let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol

let username = protocolConfiguration.username;
let password = protocolConfiguration.passwordReference;
……


```


一般情况下我们会将配置信息写在xxx.ovpn文件当中，通过获取该文件信息，转化为Data后将配置信息赋值给providerConfiguration。再由NETunnelProviderManager保存到手机。
如下：
```
tunnelProtocol.providerConfiguration = ["ovpn": configurationFileContent]
```

可实际当中我们可能不希望或者无法将所有配置信息都写到配置文件当中。比如账号密码方式验证时的动态输入账号密码信息等。这时我们除了用NEVPNProtocol为我们提供的属性外，还可以在开启连接时将我们需要的配置信息一起传递到app extension以便建立连接，下文开启VPN介绍。

**有几点比较重要**

-   tunnelProtocol.providerBundleIdentifier 为你创建的appextension的bundle Identifier. 宿主app会通过这个将我们的配置信息传递到对应appextension。
-  tunnelProtocol.providerConfiguration字典文件中key值会在app extension中作为获取配置文件的key使用，需要前后保持一致。



配置过程会打开手机设置来完成，需要进行指纹验证。成功后会可手机设配置查看相关配置信息。
![IMG_7901.PNG](https://upload-images.jianshu.io/upload_images/5873462-4d5366c32e67f2e9.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![IMG_7902.PNG](https://upload-images.jianshu.io/upload_images/5873462-ab6fcc5364c29140.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![IMG_7903.PNG](https://upload-images.jianshu.io/upload_images/5873462-2553d867ae7c75cc.PNG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

整个配置过程其实就是将文件配置信息保存到都是中的过程。这个过程只需要在宿主app中进行即可，并不涉及到app extension。

完成配置后使用NetWorkExtension下的API控制VPN的开启。这里只是告诉拓展我要建立建立，真正的连接过程还是在app extension之中利用OpenVPNAdapter完成。
开启过程如下
```
@objc func startVPN()  {
        
        
        
        self.providerManager?.loadFromPreferences(completionHandler: { (error) in
            guard error == nil else {
                // Handle an occured error
                print("loadFromPreferences error \(String(describing: error))")
                return
            }
            
            do {
                try self.providerManager?.connection.startVPNTunnel()
                
                self .addVPNStatusObserver();
                print("startVPNTunnel state \(String(describing: self.providerManager?.connection.status))")
                
            } catch {
                // Handle an occured error
                print("startVPNTunnel error \(String(describing: error))")
            }
        })
        
        
        
       
    }
    
```
###### 将额外的信息传递给app extension

上文提到我们的配置文件中可能并不能包含我们需要传递到app extension的所有信息，这时候我们可以在开启连接时将额外的配置信息传递到app extension 以便顺利建立连接。


 这里可以利用startVPNTunnel的同名函数传递参数，

```
 /*!
     * @method startVPNTunnelWithOptions:andReturnError:
     * @discussion This function is used to start the VPN tunnel using the current VPN configuration. The VPN tunnel connection process is started and this function returns immediately.
     * @param options A dictionary that will be passed to the tunnel provider during the process of starting the tunnel.
     *    If not nil, 'options' is an NSDictionary may contain the following keys
     *        NEVPNConnectionStartOptionUsername
     *        NEVPNConnectionStartOptionPassword
     * @param error If the VPN tunnel was started successfully, this parameter is set to nil. Otherwise this parameter is set to the error that occurred. Possible errors include:
     *    1. NEVPNErrorConfigurationInvalid
     *    2. NEVPNErrorConfigurationDisabled
     * @return YES if the VPN tunnel was started successfully, NO if an error occurred.
     */
    @available(iOS 9.0, *)
    open func startVPNTunnel(options: [String : NSObject]? = nil) throws

```
这里options是一个字典，API中提到可以传递NEVPNConnectionStartOptionUsername、NEVPNConnectionStartOptionPassword作为key的值。事实上我们可以传递任意key值只要在获取时对应好即可。
如下：
宿主app中
```
 self.providerManager?.connection.startVPNTunnel(options: ["username":username,"password":password])
```
app extension中
```
 let username = options["username"]
 let password = options["password"]
```




### OpenVPNAdapter

##### 集成
使用carthage将[OpenVPNAdapter](https://github.com/ss-abramchuk/OpenVPNAdapter)集成到自己项目当中。

现已支持pod方式即成。


##### 建立连接
按照[OpenVPNAdapter](https://github.com/ss-abramchuk/OpenVPNAdapter)提供的代码即可。
```
enum PacketTunnelProviderError: Error {
    case fatalError(message: String)
}

@available(iOSApplicationExtension 9.0, *)
class PacketTunnelProvider: NEPacketTunnelProvider {
    
    
    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        
        return adapter
    }()
    
    let vpnReachability = OpenVPNReachability()
    
    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        // There are many ways to provide OpenVPN settings to the tunnel provider. For instance,
        // you can use `options` argument of `startTunnel(options:completionHandler:)` method or get
        // settings from `protocolConfiguration.providerConfiguration` property of `NEPacketTunnelProvider`
        // class. Also you may provide just content of a ovpn file or use key:value pairs
        // that may be provided exclusively or in addition to file content.
        
        // In our case we need providerConfiguration dictionary to retrieve content
        // of the OpenVPN configuration file. Other options related to the tunnel
        // provider also can be stored there.
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
            else {
                fatalError()
        }
        
        
        
       
        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else {
            fatalError()
        }
        
        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent
//        configuration.settings = [
//        ]
//      
        configuration.keyDirection = 1;
        
        // Apply OpenVPN configuration
        let properties: OpenVPNProperties
        do {
            properties = try vpnAdapter.apply(configuration: configuration)
        } catch {
            completionHandler(error)
            return
        }
        
        // Provide credentials if needed
        if !properties.autologin {
            // If your VPN configuration requires user credentials you can provide them by
            // `protocolConfiguration.username` and `protocolConfiguration.passwordReference`
            // properties. It is recommended to use persistent keychain reference to a keychain
            // item containing the password.

            guard let username: String = protocolConfiguration.username else {
                fatalError()
            }

            // Retrieve a password from the keychain
//            guard let password: String = ... {
//                fatalError()
//            }

            let credentials = OpenVPNCredentials()
            credentials.username = username
//            credentials.password = password

            do {
                try vpnAdapter.provide(credentials: credentials)
            } catch {
                completionHandler(error)
                return
            }
        }
        
        
    
        
        // Checking reachability. In some cases after switching from cellular to
        // WiFi the adapter still uses cellular data. Changing reachability forces
        // reconnection so the adapter will use actual connection.
        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }
        
        // Establish connection and wait for .connected event
        startHandler = completionHandler
        vpnAdapter.connect()
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler
        
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        
        vpnAdapter.disconnect()
    }
    
}

@available(iOSApplicationExtension 9.0, *)
extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    
    // OpenVPNAdapter calls this delegate method to configure a VPN tunnel.
    // `completionHandler` callback requires an object conforming to `OpenVPNAdapterPacketFlow`
    // protocol if the tunnel is configured without errors. Otherwise send nil.
    // `OpenVPNAdapterPacketFlow` method signatures are similar to `NEPacketTunnelFlow` so
    // you can just extend that class to adopt `OpenVPNAdapterPacketFlow` protocol and
    // send `self.packetFlow` to `completionHandler` callback.
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        setTunnelNetworkSettings(networkSettings) { (error) in
            completionHandler(error == nil ? self.packetFlow : nil)
        }
    }
    

    
    // Process events returned by the OpenVPN library
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            
            guard let startHandler = startHandler else { return }
            
            startHandler(nil)
            self.startHandler = nil
            
        case .disconnected:
            guard let stopHandler = stopHandler else { return }
            
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            
            stopHandler()
            self.stopHandler = nil
            
        case .reconnecting:
            reasserting = true
            
        default:
            break
        }
    }
    
    // Handle errors thrown by the OpenVPN library
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        // Handle only fatal errors
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }
        
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        
        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }
    
    // Use this method to process any log message returned by OpenVPN library.
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        // Handle log messages
        print("handleLogMessage \(logMessage)")
        NSLog("handleLogMessage \(logMessage)")
    }

    
//    Printing description of logMessage:
//    "Transport Error: Transport error on \'223.100.8.226: NETWORK_EOF_ERROR\n"
//    Printing description of error:
//    Error Domain=me.ss-abramchuk.openvpn-adapter.error-domain Code=26 "OpenVPN error occured" UserInfo={NSLocalizedFailureReason=General transport error, me.ss-abramchuk.openvpn-adapter.error-key.message=Transport error on '223.100.8.226: NETWORK_EOF_ERROR, me.ss-abramchuk.openvpn-adapter.error-key.fatal=false, NSLocalizedDescription=OpenVPN error occured}


   
}
```

建立成功后手机状态栏会显示出VPN的标志。
![56B86A1C-870C-4E78-93CF-27E72152D277.png](https://upload-images.jianshu.io/upload_images/5873462-a274e1456c73a303.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 总结
整个过程大致为：我们在宿主app中设置tunnelProviderProtocol ，然后利用tunnelProviderManager.saveToPreferences方法将tunnelProviderProtocol保存到手机，随后用户利用tunnelProviderManager.connection.startVPNTunnel告诉app extension开始连接，连接时app extension获取配置信息tunnelProviderProtocol，然后OpenVPNAdapter利用这些配置信息来建立连接。

在宿主app中调用startVPN方法后，会在建立连接过程中执行extension中的代码。
**⚠️Dubug ->Attach to Process 或者Attach to Process by PID or Name 可以进行extension中代码调试。通常的运行是无法进行extension代码调试的。**
![9F3091708735E0ED59238EB708A02F62.jpg](https://upload-images.jianshu.io/upload_images/5873462-e1da5618a3085453.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)








##### 配置文件
配置文件在OpenVPNAdapter中支持两种方式
健值对方式
```
remote 223.100.8.226 11194
```
标签方式
```
<ca>
</ca>
```
config文件配置基本两种方式
- 用户名密码验证方式。
- 证书验证方式。

根据实际情况大致配置如下
```
client
#路由模式
dev tun 
#改为tcp
proto tcp
#OpenVPN服务器的外网IP和端口
remote xxx.xxx.x.xxx xxxxx
resolv-retry infinite
nobind
persist-key
persist-tun
#ca ca.crt
#cert test1.crt
#key test1.key
ns-cert-type server
#tls-auth ta.key 1
comp-lzo
verb 3
#密码认证相关
#auth-user-pass

```
通常情况下这是一种比较标准常见的配置文件。但是在OpenVPNAdapter可能会存在问题。OpenVPNAdapter可能并不能完全的支持所有标签，导致我们在建立连接过程中出现很多问题。详细参考 常见错误。

###### 证书方式
直接将证书文件复制密钥到对应标签当中
例如：
```
<tls-auth>
-----BEGIN OpenVPN Static key V1-----
···从你的ta.key中复制过来
-----END OpenVPN Static key V1-----
</tls-auth>
```
同理还有ca cret key等凡是涉及到外部文件的，都直接将文件内容复制到配置文件里面，在openVPNAdapter中可能识别不了文件路径的内容。

###### 账号密法方式(该方式待验证)
、、、
auth-user-pass username password
、、、


参考资料
[openVPN的客户端的client.ovpn配置.](https://blog.csdn.net/wolfking0608/article/details/70769018)





#### 常见错误

**(Error) error = <variable not available>变量不支持。**
.ovpn中tls-auth变量导致的OpenVPNAdapter并不支持健值对这种方法
```
tls-auth ta.key 1
```
改为
```
<tls-auth>
-----BEGIN OpenVPN Static key V1-----
···从你的ta.key中复制过来
-----END OpenVPN Static key V1-----
</tls-auth>

```

**Error Domain=me.ss-abramchuk.openvpn-adapter.error-domain Code=67 "Failed to establish connection with OpenVPN server"建立连接失败**
原因很多种，例如：
![066D286D-3B51-49B4-A4BE-2AA9081A3E7E.png](https://upload-images.jianshu.io/upload_images/5873462-beee0a52ab995bd1.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
ca 证书文件格式不正确。因为OpenVPNAdapter认为我们我们配置的ca ca.crt中ca.crt为我们的证书文件内容。但实际上它是一个证书文件的路径。所以我们也使用标签方式配置
```
<ca>
....
</ca>
```
同理
```
#ca ca.crt 
#cert test1.crt
#key test1.key
#tls-auth ta.key 1
```
都使用标签方式进行配置。



**"UNUSED OPTIONS\n4 [resolv-retry] [infinite] \n5 [nobind] \n6 [persist-key] \n7 [persist-tun] \n10 [verb] [3] \n11 [key-deriction] [1] \n\n"**

![317545E1-8DE2-4298-8FA1-867AC78544B4.png](https://upload-images.jianshu.io/upload_images/5873462-d1dc266b05eab5e5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

有几个标签在没有用，应该是能够识别这些标签但是无法使用。
其中key-deriction比较重要，所以我们在代码中配置
```
configuration.keyDirection = 1;
```



**"TCP recv EOF\n"TCP EOF错误**
**Transport error on '223.100.8.226: NETWORK_EOF_ERROR**

![3937EB0C-EA6A-404A-92D6-935F8EAF4935.png](https://upload-images.jianshu.io/upload_images/5873462-28831e8a5ad9e0dc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
由于key-deriction无法使用导致。在代码中配置后解决。





**<cipher>AES-128-CBC</cipher>**
```
Optional<String>

 some : "client\r\ndev tun\r\nproto udp\r\nremote [120.79.18.134](120.79.18.134) 1194\r\nresolv-retry infinite\r\nnobind\r\npersist-key\r\npersist-tun\r\nns-cert-type server\r\n<cipher>AES-128-CBC</cipher>\r\nkey-deriction 1\r\nverb...
```
配置文件中去除 <cipher>AES-128-CBC</cipher>该标签解决，


**部分用户密码登录方式无法连接**
appextension 中添加下列语句。
```
 configuration.disableClientCert = true;
```

**OpenVPNAdapterPacketFlow 类型错误**
添加一下代码 让NEPacketTunnelFlow实现OpenVPNAdapterPacketFlow协议
```
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow{}
```

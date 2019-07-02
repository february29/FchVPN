//
//  NEPacketTunnelFlow+OpenVPN.swift
//  PacketTunnel
//
//  Created by 周荣水 on 2017/12/6.
//  Copyright © 2017年 周荣水. All rights reserved.
//

import Foundation
import NetworkExtension
import OpenVPNAdapter

@available(iOSApplicationExtension 9.0, *)
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow{}

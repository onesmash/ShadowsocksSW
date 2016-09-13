//
//  ViewController.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/7/27.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ViewController.h"
#import "SSClient.h"
#import "SSTCPRelayRequest.h"
#import "SSTCPRelaySession.h"
#import "net/URLRequest.h"

@interface ViewController () {
}

@end

SSClient client(WukongBase::Net::IPAddress("127.0.0.1", 8989), kCipherTypeAES256CFB, "howtoget!@");

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    client.setRequestCallback([](const SSTCPRelaySession& session, const std::shared_ptr<SSTCPRelayRequest>&, bool success) {
//        WukongBase::Net::URLRequest request("http://onesmash.github.io");
//        request.setHTTPMethod("GET");
//        session.sendData(request.pack());
//    });
//    client.setWriteCompleteCallback([](const SSTCPRelaySession&, const WukongBase::Net::Packet& packet, bool success) {
//        
//    });
//    client.setMessageCallback([](const SSTCPRelaySession&, const std::shared_ptr<WukongBase::Base::IOBuffer>& buffer) {
//        printf(buffer->data());
//    });
//    client.setCloseCallback([](const SSTCPRelaySession&){
//        
//    });
//    std::shared_ptr<SSTCPRelayRequest> request(new SSTCPRelayRequest("onesmash.github.io", 80));
//    client.sendTCPRelayRequest(request);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

//
//  ViewController.m
//  CommonWebViewTest
//
//  Created by 张书孟 on 2017/12/26.
//  Copyright © 2017年 张书孟. All rights reserved.
//

#import "ViewController.h"
#import "CommonWebView.h"

@interface ViewController ()<CommonWebViewDelegate>

@property (nonatomic, strong) CommonWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *libraryPath =  NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"%@",libraryPath);
    
    [self setupNavigationItem];
    _webView = [CommonWebView webViewWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//    _webView.isNavigationBarOrTranslucent = NO;
    _webView.delegate = self;
    [_webView loadRequestWithUrlString:@"https://www.baidu.com"];
    [self.view addSubview:_webView];
}

- (void)setupNavigationItem {
    
    UIBarButtonItem *leftBarButtonItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemRewind) target:self action:@selector(leftBarButtonItemAction)];
    
    self.navigationItem.leftBarButtonItems = @[leftBarButtonItem1];
    
    UIBarButtonItem *rightBarButtonItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemRefresh) target:self action:@selector(rightBarButtonItemAction)];
    UIBarButtonItem *rightBarButtonItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFastForward) target:self action:@selector(rightBarButtonItemAction1)];
    self.navigationItem.rightBarButtonItems = @[rightBarButtonItem1, rightBarButtonItem2];
}

// 刷新
- (void)rightBarButtonItemAction {
    [self.webView removeAllCached:^{
        
    }];
}

// goForward
- (void)rightBarButtonItemAction1 {
    [self.webView goForward];
}

- (void)leftBarButtonItemAction {
    [self.webView goBack];
}

- (void)webView:(CommonWebView *)webView didFinishLoadWithURL:(NSURL *)url {
    self.navigationItem.title = webView.navigationItemTitle;
}


@end

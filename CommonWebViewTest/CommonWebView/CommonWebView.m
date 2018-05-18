//
//  CommonWebView.m
//  Tools
//
//  Created by 张书孟 on 2017/12/15.
//  Copyright © 2017年 张书孟. All rights reserved.
//

#import "CommonWebView.h"
#import <WebKit/WebKit.h>


#define kAYNavigationBarHeight ([[UIApplication sharedApplication] statusBarFrame].size.height + 44.f)

@interface CommonWebView () <WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate>

// WKWebView
@property (nonatomic, strong) WKWebView *wkWebView;
// 进度条
@property (nonatomic, strong) UIProgressView *progressView;
//图片链接数组
@property (strong, nonatomic)NSMutableArray * mArrayUrl;

@end

@implementation CommonWebView

static CGFloat const navigationBarHeight = 64;
static CGFloat const progressViewHeight = 2;

/// dealloc
- (void)dealloc {
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    self.wkWebView = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addWkWebView];
        [self addProgressView];
    }
    return self;
}

#pragma mark - private
// 9.0以下将文件夹copy到tmp目录
- (NSURL *)fileURLForBuggyWKWebView:(NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *temDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSURL *dstURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    
    [fileManager removeItemAtURL:dstURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:dstURL error:&error];
    
    return dstURL;
}

#pragma mark Public
+ (instancetype)webViewWithFrame:(CGRect)frame {
    return [[self alloc] initWithFrame:frame];
}

// 加载 web
- (void)loadRequestWithUrlString:(NSString *)urlString {
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

// 加载本地资源
- (void)loadFileName:(NSString *)fileName {
    
    NSString *fileURL = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSString *readAccessToURL = [fileURL stringByDeletingLastPathComponent]; // 获取上一级路径
    if (@available(iOS 9.0, *)) {
        [self.wkWebView loadFileURL:[NSURL fileURLWithPath:fileURL] allowingReadAccessToURL:[NSURL fileURLWithPath:readAccessToURL]];
    } else { // 9.0以下
        if(fileURL) {
            NSURL *fileUrl = [NSURL fileURLWithPath:fileURL];
            // 把文件夹转到tmp目录
            fileUrl = [self fileURLForBuggyWKWebView:fileUrl];
            NSURL *realUrl = [NSURL fileURLWithPath:fileUrl.path];
            NSURLRequest *request = [NSURLRequest requestWithURL:realUrl];
            [self.wkWebView loadRequest:request];
        }
    }
}

//// 加载 HTML
//- (void)loadHTMLString:(NSString *)HTMLString {
//    [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
//}

// 刷新数据
- (void)reloadData {
    [self.wkWebView reload];
}

// 返回
- (void)goBack {
    if ([self.wkWebView canGoBack]) {
        [self.wkWebView goBack];
    }
}

// 前进
- (void)goForward {
    if ([self.wkWebView canGoForward]) {
        [self.wkWebView goForward];
    }
}

// 清除缓存
- (void)removeAllCached:(void(^)(void))completion {
    if (@available(iOS 9.0, *)) {
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            if (completion) {
                completion();
            }
        }];
    } else {
        //iOS8清除缓存
        NSString *libraryPath =  NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:nil];
    }
}

#pragma mark KVO
// KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        self.progressView.alpha = 1.0;
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        if (self.wkWebView.estimatedProgress >= 0.97) {
            [UIView animateWithDuration:0.1 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.progressView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0 animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

#pragma mark  加载的状态回调（WKNavigationDelegate）
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:self];
    }
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    self.navigationItemTitle = webView.title;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didCommitWithURL:)]) {
        [self.delegate webView:self didCommitWithURL:webView.URL];
    }
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.navigationItemTitle = webView.title;
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didFinishLoadWithURL:)]) {
        [self.delegate webView:self didFinishLoadWithURL:webView.URL];
    }
    self.progressView.alpha = 0.0;
    [self getImageUrlByJS:webView];
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self didFailLoadWithError:error];
    }
    self.progressView.alpha = 0.0;
}

#pragma mark getter
- (void)addWkWebView {
    if (!_wkWebView) {
        _wkWebView = [[WKWebView alloc] initWithFrame:self.bounds];
        _wkWebView.UIDelegate = self;
        _wkWebView.navigationDelegate = self;
        [self addSubview:_wkWebView];
        // KVO
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:nil];
    }
}

- (void)addProgressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.trackTintColor = [UIColor clearColor];
        // 高度默认有导航栏且有穿透效果
        _progressView.frame = CGRectMake(0, navigationBarHeight, self.frame.size.width, progressViewHeight);
        // 设置进度条颜色
        _progressView.tintColor = [UIColor greenColor];
        [self addSubview:_progressView];
    }
}

//图片数组
- (NSMutableArray *)mArrayUrl {
    if (!_mArrayUrl) {
        _mArrayUrl = [NSMutableArray array];
    }
    return _mArrayUrl;
}

#pragma mark ========= 点击获取所有图片，并查看大图 ========================
//通过js获取htlm中图片url
-(void)getImageUrlByJS:(WKWebView *)wkWebView{
    
    //js方法遍历图片添加点击事件返回图片个数
    //这里是js，主要目的实现对url的获取
    static  NSString * const jsGetImages =
    @"function getImages(){\
    var objs = document.getElementsByTagName(\"img\");\
    var imgScr = '';\
    for(var i=0;i<objs.length;i++){\
    imgScr = imgScr + objs[i].src + '+';\
    };\
    return imgScr;\
    };";
    
    //用js获取全部图片,传质给js
    [wkWebView evaluateJavaScript:jsGetImages completionHandler:nil];
    
    //得到所有图片
    NSString *jsString = @"getImages()";
    
    [wkWebView evaluateJavaScript:jsString completionHandler:^(id Result, NSError * error) {
        
        NSString *resurlt=[NSString stringWithFormat:@"%@",Result];
        
        if([resurlt hasPrefix:@"+"]){
            
            resurlt=[resurlt substringFromIndex:1];
            
        }
        
        NSArray * array=[resurlt componentsSeparatedByString:@"+"];
        
        [self.mArrayUrl removeAllObjects];
        //添加到可变数组
        [self.mArrayUrl addObjectsFromArray:array];
        //移除最后一个元素（空白）
        [self.mArrayUrl removeLastObject];
        
        // NSLog(@"得到所有图片url：%@",self.mArrayUrl);
        
    }];
}

//点击手势
- (void)handleTapPress:(UITapGestureRecognizer *)sender{
    
    CGPoint touchPoint = [sender locationInView:self];
    // 获取长按位置对应的图片url的JS代码
    NSString *imgJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    // 执行对应的JS代码 获取url
    
    [self.wkWebView evaluateJavaScript:imgJS completionHandler:^(id _Nullable imgUrl, NSError * _Nullable error) {
        if (imgUrl) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgUrl]];
            UIImage *image = [UIImage imageWithData:data];
            if (!image) {
                NSLog(@"读取图片失败");
                return;
            }
            //获取到图片image
            
            //图片大于0才创建
            if (self.mArrayUrl.count>0) {
                NSInteger currentIndex = 0;
                //得到索引
                for (int i= 0; i< self.mArrayUrl.count; i++) {
                    if ([imgUrl isEqual:self.mArrayUrl[i]]) {
                        //当前点击了第几张图片
                        currentIndex = i;
                    }
                }
                
                //控制器跳转
//                JZAlbumViewController *jzAlbumVC = [[JZAlbumViewController alloc]init];
//                //当前点击图片的索引
//                jzAlbumVC.currentIndex = currentIndex;
//                //imgArr可以为url数组, 可以为urlString 数组, 可以为二进制 UIImage 数组
//                jzAlbumVC.imgArr = self.mArrayUrl;
//
//                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:jzAlbumVC animated:NO completion:nil];
                
            }else{
                //如果加载完后拿不到所有图片数组，就查看当前点击的图片
                //控制器跳转
//                JZAlbumViewController *jzAlbumVC = [[JZAlbumViewController alloc]init];
//                //当前点击图片的索引
//                jzAlbumVC.currentIndex = 0;
//                //imgArr可以为url数组, 可以为urlString 数组, 可以为二进制 UIImage 数组
//                jzAlbumVC.imgArr = [NSMutableArray arrayWithArray:@[imgUrl]];
//
//                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:jzAlbumVC animated:NO completion:nil];
                
                
            }
        }
    }];
    
    
}

#pragma mark  setter

- (void)setProgressViewColor:(UIColor *)progressViewColor {
    _progressViewColor = progressViewColor;
    
    if (progressViewColor) {
        _progressView.tintColor = progressViewColor;
    }
}

- (void)setIsNavigationBarOrTranslucent:(BOOL)isNavigationBarOrTranslucent {
    _isNavigationBarOrTranslucent = isNavigationBarOrTranslucent;
    
    if (isNavigationBarOrTranslucent == YES) { // 导航栏存在且有穿透效果
        _progressView.frame = CGRectMake(0, navigationBarHeight, self.frame.size.width, progressViewHeight);
    } else { // 导航栏不存在或者没有有穿透效果
        _progressView.frame = CGRectMake(0, 0, self.frame.size.width, progressViewHeight);
    }
}

@end

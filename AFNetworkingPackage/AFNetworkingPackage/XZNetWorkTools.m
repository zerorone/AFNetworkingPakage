//
//  XZNetWorkTools.m
//  AFNetworkingPackage
//
//  Created by 晓 &zerone on 16/6/4.
//  Copyright © 2016年 xiao. All rights reserved.
//

#import "XZNetWorkTools.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager.h>

#import <CommonCrypto/CommonDigest.h>

@interface NSString  (md5)
+(NSString *)md5NetWorking:(NSString *)URLString;

@end

@implementation NSString (md5)

+(NSString *)md5NetWorking:(NSString *)URLString
{
    if (URLString == nil || URLString.length ==0) {
        return  nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
    CC_MD5([URLString UTF8String], (int)[URLString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
    
    NSMutableString * strM = [NSMutableString string];
    
    for (i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [strM appendFormat:@"%02x",(int)digest[i]];
    }
    return [strM copy];
    
}

@end



@interface XZNetWorkTools ()

@end


static NSString * xz_baseURL = nil;
static NSTimeInterval  xz_timeOut = 60.0f ;
static BOOL  xz_shouldObtain = NO;
static BOOL  xz_isGetCache = YES ;
static BOOL  xz_isPostCache = YES;
static BOOL  xz_isAutoEncode = NO;
static BOOL  xz_isCallBack = YES;
static BOOL xz_shouldAutoEncode = YES;
static BOOL xz_isEnableInterfaceDebug = YES;
static BOOL xz_isRefresh = NO;
static XZRequestType  xz_requestType = kXZRequestTypeJSON;
static XZResponseType  xz_responseType =kXZResponseTypeJSON;
static NSDictionary * xz_requestHeaders = nil;
static NSMutableArray * xz_requestTasks;

@implementation XZNetWorkTools

#pragma mark - 公开的方法
#pragma mark - BaseURL
+ (void)setBaseURL:(NSString *)baseURL
{
    xz_baseURL = baseURL;
}
+ (NSString *)baseURL
{
    return xz_baseURL;
}

#pragma mark - timeOut
+(void)setTimeOut:(NSTimeInterval)timeOut
{
    xz_timeOut = timeOut;
}

#pragma mark - shouldObtain BOOL值
+(void)obtainDataFromCacheWhenNetWorkUnConnect:(BOOL)shouldObtain
{
    xz_shouldObtain = shouldObtain;
}


#pragma mark - 是否缓存GET/POST的数据

+(void)cacheGetRequest:(BOOL)isCacheGet cachePostRequest:(BOOL)isCachePost
{
    xz_isGetCache = isCacheGet;
    xz_isPostCache = isCachePost;
}


#pragma mark - 配置请求格式和响应格式
+(void)ocnfigRequestType:(XZRequestType)requestType
            responseType:(XZResponseType)responseType
     shouldAutoEncodeURL:(BOOL)shouldAutoEncode
shouldCallBackOnCancelRequest:(BOOL)shouldCallBack
{
    xz_requestType = requestType;
    xz_responseType = responseType;
    xz_isAutoEncode = shouldAutoEncode;
    xz_isCallBack = shouldCallBack;
}

#pragma mark - 配置只会请求一次公共请求头
+(void)configCommonRequestHttpHeaders:(NSDictionary *)headers
{
    xz_requestHeaders = headers;
}

#pragma mark - 根据URL地址取消请求
+(void)cancelRequestWithURL:(NSString *)URL
{
    if (URL ==nil || URL.length ==0) {
        return;
    }
    
    @synchronized(self) {
       [ [self allTasks] enumerateObjectsUsingBlock:^(XZURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[XZURLSessionTask class]] && [task.currentRequest.URL.absoluteString hasSuffix:URL]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
       }];
    }
}

#pragma mark - 取消所有的请求
+(void)cancelAllRequest
{
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(XZURLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allTasks] removeAllObjects];
    }
}



#pragma mark - 普通的get网络请求
+(XZURLSessionTask *)getWithURL:(NSString *)url success:(XZResponseSuccess)success failure:(XZResponseError)error
{
  return [self requestWithURL:url refreshCache:xz_isRefresh httpMedth:kXZHttpMethodGET params:nil progress:nil success:success fail:error];
}

#pragma mark - get请求带是否刷新缓存的参数
+(XZURLSessionTask *)getWithURL:(NSString *)url refreshCache:(BOOL)refreshCache success:(XZResponseSuccess)success failure:(XZResponseError)error
{
    return [self requestWithURL:url refreshCache:refreshCache httpMedth:kXZHttpMethodGET params:nil progress:nil success:success fail:error];
}

#pragma mark - 带参数的get请求
+(XZURLSessionTask *)getWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params success:(XZResponseSuccess)success failure:(XZResponseError)error
{
    return [self requestWithURL:url refreshCache:refreshCache httpMedth:kXZHttpMethodGET params:params progress:nil success:success fail:error];
}

#pragma mark -  带进度的get请求
+(XZURLSessionTask *)getWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params progress:(XZGetDownloadProgress)progress success:(XZResponseSuccess)success failure:(XZResponseError)error
{
    return [self requestWithURL:url refreshCache:refreshCache httpMedth:kXZHttpMethodGET params:params progress:progress success:success fail:error];
}

#pragma mark -  post的请求
+(XZURLSessionTask *)postWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params success:(XZResponseSuccess)success failure:(XZResponseError)error
{
    return [self requestWithURL:url refreshCache:refreshCache httpMedth:kXZHttpMethodPOST params:params progress:nil success:success fail:error];
}

//带进度的post请求
+(XZURLSessionTask *)postWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params progress:(XZPostDownloadProgress)progress success:(XZResponseSuccess)success failure:(XZResponseError)error
{
    return [self requestWithURL:url refreshCache:refreshCache httpMedth:kXZHttpMethodPOST params:params progress:progress success:success fail:error];
}

#pragma mark - 图片上传接口，若不指定baseurl，可传完整的url
+ (XZURLSessionTask *)uploadWithImage:(UIImage *)image
                                  url:(NSString *)url
                             filename:(NSString *)filename
                                 name:(NSString *)name
                             mimeType:(NSString *)mimeType
                           parameters:(NSDictionary *)parameters
                             progress:(XZUploadProgressBlocck)progress
                              success:(XZResponseSuccess)success
                                 fail:(XZResponseError)fail
{
    if ([self baseURL] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseURL], url]] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encode:url];
    }
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    AFHTTPSessionManager *manager = [self manager];
    XZURLSessionTask *session = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        
        NSString *imageFileName = filename;
        if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }
        
        // 上传图片，以文件流的格式
        [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callback:success];
        
        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:absolute
                                  params:parameters];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [[self allTasks] removeObject:task];
        
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
            [self logWithFailError:error url:absolute params:nil];
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}


#pragma mark - 上传文件操作
+ (XZURLSessionTask *)uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(XZUploadProgressBlocck)progress
                                success:(XZResponseSuccess)success
                                   fail:(XZResponseError)fail
{
    if ([NSURL URLWithString:uploadingFile] == nil) {
        NSLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
        return nil;
    }
    
    NSURL *uploadURL = nil;
    if ([self baseURL] == nil) {
        uploadURL = [NSURL URLWithString:url];
    } else {
        uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseURL], url]];
    }
    
    if (uploadURL == nil) {
        NSLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
        return nil;
    }
    
    AFHTTPSessionManager *manager = [self manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
    XZURLSessionTask *session = nil;
    
    [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];
        
        [self successResponse:responseObject callback:success];
        
        if (error) {
            [self handleCallbackWithError:error fail:fail];
            
            if ([self isDebug]) {
                [self logWithFailError:error url:response.URL.absoluteString params:nil];
            }
        } else {
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:response.URL.absoluteString
                                      params:nil];
            }
        }
    }];
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

#pragma mark - 下载文件
+ (XZURLSessionTask *)downloadWithUrl:(NSString *)url
                           saveToPath:(NSString *)saveToPath
                             progress:(XZDownloadProgressBlocck)progressBlock
                              success:(XZResponseSuccess)success
                              failure:(XZResponseError)failure
{
    if ([self baseURL] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseURL], url]] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFHTTPSessionManager *manager = [self manager];
    
    XZURLSessionTask *session = nil;
    
    session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        if (progressBlock) {
            progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL URLWithString:saveToPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [[self allTasks] removeObject:session];
        
        if (error == nil) {
            if (success) {
                success(filePath.absoluteString);
            }
            
            if ([self isDebug]) {
                NSLog(@"Download success for url %@",
                          [self absoluteUrlWithPath:url]);
            }
        } else {
            [self handleCallbackWithError:error fail:failure];
            
            if ([self isDebug]) {
                NSLog(@"Download fail for url %@, reason : %@",
                          [self absoluteUrlWithPath:url],
                          [error description]);
            }
        }
    }];
    
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
}

#pragma mark - 获取缓存的大小
+(NSUInteger)totalCacheSize
{
    NSString *directoryPath = cachePath();
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:&error];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                          error:&error];
                    if (!error) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    
    return total;
}

#pragma mark - 清理缓存
+(void)clearCaches
{
    NSString *directoryPath = cachePath();
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        
        if (error) {
            NSLog(@"XZNetworking clear caches error: %@", error);
        } else {
            NSLog(@"XZNetworking clear caches ok");
        }
    }
}


#pragma mark - 私有方法
#pragma mark - 懒加载建一个缓存池
+(NSMutableArray *)allTasks{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (xz_requestTasks == nil) {
            xz_requestTasks = [NSMutableArray array];
        }
    });
    return xz_requestTasks;
}

#pragma mark - 一个总的网络请求方法
+ (XZURLSessionTask *)requestWithURL:(NSString *)url
                          refreshCache:(BOOL)refreshCache
                             httpMedth:(NSUInteger)httpMethod
                                params:(NSDictionary *)params
                              progress:(XZDownloadProgressBlocck)progress
                               success:(XZResponseSuccess)success
                                  fail:(XZResponseError)fail
{
    AFHTTPSessionManager *manager = [self manager];
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    if ([self baseURL] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        NSURL *absouluteURL = [NSURL URLWithString:absolute];
        
        if (absouluteURL == nil) {
            NSLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    if ([self shouldEncode]) {
        url = [self encode:url];
    }
    
    XZURLSessionTask *session = nil;
    
    if (httpMethod == kXZHttpMethodGET) {
        if (xz_isGetCache && !refreshCache) {// 获取缓存
            id response = [XZNetWorkTools cahceResponseWithURL:absolute
                                                   parameters:params];
            if (response) {
                if (success) {
                    [self successResponse:response callback:success];
                }
                return nil;
            }
        }
        
        session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            
            if (xz_isGetCache) {
                [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
            }
            
            [[self allTasks] removeObject:task];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && xz_isGetCache) {// 获取缓存
                id response = [XZNetWorkTools cahceResponseWithURL:absolute
                                                       parameters:params];
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
            }
        }];
    } else if (httpMethod == kXZHttpMethodPOST) {
        if (xz_isPostCache && !refreshCache) {// 获取缓存
            id response = [XZNetWorkTools cahceResponseWithURL:absolute
                                                   parameters:params];
            
            if (response) {
                if (success) {
                    [self successResponse:response callback:success];
                    
                    if ([self isDebug]) {
                        [self logWithSuccessResponse:response
                                                 url:absolute
                                              params:params];
                    }
                }
                
                return nil;
            }
        }
        
        session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            [self successResponse:responseObject callback:success];
            
            if (xz_isPostCache) {
                [self cacheResponseObject:responseObject request:task.currentRequest  parameters:params];
            }
            
            [[self allTasks] removeObject:task];
            
            if ([self isDebug]) {
                [self logWithSuccessResponse:responseObject
                                         url:absolute
                                      params:params];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            [[self allTasks] removeObject:task];
            
            if ([error code] < 0 && xz_isPostCache) {// 获取缓存
                id response = [XZNetWorkTools cahceResponseWithURL:absolute
                                                       parameters:params];
                
                if (response) {
                    if (success) {
                        [self successResponse:response callback:success];
                        
                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params];
                        }
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];
                    
                    if ([self isDebug]) {
                        [self logWithFailError:error url:absolute params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:params];
                }
            }
        }];
    }
    
    if (session) {
        [[self allTasks] addObject:session];
    }
    
    return session;
    
}

#pragma mark - 拼接请求地址
+ (NSString *)absoluteUrlWithPath:(NSString *)path {
    if (path == nil || path.length == 0) {
        return @"";
    }
    
    if ([self baseURL] == nil || [[self baseURL] length] == 0) {
        return path;
    }
    
    NSString *absoluteUrl = path;
    
    if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
        absoluteUrl = [NSString stringWithFormat:@"%@%@",
                       [self baseURL], path];
    }
    
    return absoluteUrl;
}

#pragma mark - 请求管理的配置SessionManager
+ (AFHTTPSessionManager *)manager {
    // 开启转圈圈
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = nil;;
    if ([self baseURL] != nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseURL]]];
    } else {
        manager = [AFHTTPSessionManager manager];
    }
    
    switch (xz_requestType) {
        case kXZRequestTypeJSON: {
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        }
        case kXZRequestTypePlainText: {
            manager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    
    switch (xz_responseType) {
        case kXZResponseTypeJSON: {
            manager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        }
        case kXZResponseTypeXML: {
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        }
        case kXZResponseTypeData: {
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        }
        default: {
            break;
        }
    }
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    
    for (NSString *key in xz_requestHeaders.allKeys) {
        if (xz_requestHeaders[key] != nil) {
            [manager.requestSerializer setValue:xz_requestHeaders[key] forHTTPHeaderField:key];
        }
    }
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    
    manager.requestSerializer.timeoutInterval = xz_timeOut;
    
    // 设置允许同时最大并发数量，过大容易出问题
    manager.operationQueue.maxConcurrentOperationCount = 3;
    return manager;
}

#pragma mark - 是否应该启用编码
+ (BOOL)shouldEncode
{
    return xz_shouldAutoEncode;
}

#pragma mark - 编码地址
+(NSString *)encode:(NSString *)url
{
    return [self xz_URLEncode:url];
}

+ (NSString *)xz_URLEncode:(NSString *)url
{
    NSString *newString =
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)url,
                                                              NULL,
                                                              CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
    if (newString) {
        return newString;
    }
    
    return url;
}

#pragma mark - 根据地址缓存数据
+ (id)cahceResponseWithURL:(NSString *)url parameters:params {
    id cacheData = nil;
    
    if (url) {
        // Try to get datas from disk
        NSString *directoryPath = cachePath();
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
        NSString *key = [NSString md5NetWorking:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        
        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
            NSLog(@"Read data from cache for url: %@\n", url);
        }
    }
    
    return cacheData;
}

#pragma mark - 成功回调
+ (void)successResponse:(id)responseData callback:(XZResponseSuccess)success {
    if (success) {
        success([self tryToParseData:responseData]);
    }
}

#pragma mark - 错误的回调
+ (void)handleCallbackWithError:(NSError *)error fail:(XZResponseError)fail {
    if ([error code] == NSURLErrorCancelled) {
        if (xz_isCallBack) {
            if (fail) {
                fail(error);
            }
        }
    } else {
        if (fail) {
            fail(error);
        }
    }
}
#pragma mark - 解析返回的数据
+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        // 尝试解析成JSON
        if (responseData == nil) {
            return responseData;
        } else {
            NSError *error = nil;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:NSJSONReadingMutableContainers
                                                                       error:&error];
            
            if (error != nil) {
                return responseData;
            } else {
                return response;
            }
        }
    } else {
        return responseData;
    }
}

#pragma mark - 缓存地址
static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/XZNetworkingCaches"];
}

#pragma mark - 缓存get数据
+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params {
    if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
        NSString *directoryPath = cachePath();
        
        NSError *error = nil;
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error) {
                NSLog(@"create cache dir error: %@\n", error);
                return;
            }
        }
        
        NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
        NSString *key = [NSString md5NetWorking:absoluteURL];
        NSString *path = [directoryPath stringByAppendingPathComponent:key];
        NSDictionary *dict = (NSDictionary *)responseObject;
        
        NSData *data = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        
        if (data && error == nil) {
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            if (isOk) {
                NSLog(@"cache file ok for request: %@\n", absoluteURL);
            } else {
                NSLog(@"cache file error for request: %@\n", absoluteURL);
            }
        }
    }
}

#pragma mark - 解析请求到的数据
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}

#pragma mark - 调试打印
+ (BOOL)isDebug {
    return xz_isEnableInterfaceDebug;
}

#pragma mark - 成功打印
+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    NSLog(@"\n");
    NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              params,
              [self tryToParseData:response]);
}

#pragma mark - 失败打印
+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    NSLog(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        NSLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
                  [self generateGETAbsoluteURL:url params:params],
                  format,
                  params);
    } else {
        NSLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
                  [self generateGETAbsoluteURL:url params:params],
                  format,
                  params,
                  [error localizedDescription]);
    }
}


@end

//
//  XZNetWorkTools.h
//  AFNetworkingPackage
//
//  Created by 晓 &zerone on 16/6/4.
//  Copyright © 2016年 xiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 *  @author 晓
 *
 *  下载进度指示Block
 *
 *  @param readBytes      当前读取的字节数
 *  @param totalReadBytes 总共的字节数
 */
typedef void(^XZDownloadProgressBlocck)(int64_t readBytes , ino64_t totalReadBytes);

typedef XZDownloadProgressBlocck XZGetDownloadProgress;
typedef XZDownloadProgressBlocck XZPostDownloadProgress;

/**
 *  @author 晓
 *
 *  上传进度指示
 *
 *  @param writeBytes      当前写了数据
 *  @param totalWriteBytes 总共要写入多少数据
 */
typedef void(^XZUploadProgressBlocck)(int64_t writeBytes , ino64_t totalWriteBytes);

//返回的数据类型
typedef NS_ENUM(NSInteger ,XZResponseType) {
    kXZResponseTypeJSON = 1, //默认
    kXZResponseTypeXML = 2,
    kXZResponseTypeData = 3
};

/**
 *  @author 晓
 *
 *  请求的数据类型
 */
typedef NS_ENUM(NSInteger ,XZRequestType) {
    kXZRequestTypeJSON = 1, //默认
    kXZRequestTypePlainText =2  //普通的text/html
};


typedef NS_ENUM(NSInteger ,XZHttpMethod) {
    kXZHttpMethodGET = 1,
    kXZHttpMethodPOST = 2
};

/**
 *  @author 晓
 *
 *  定义成功和失败的Block
 * 这里使用NSURLSessionTask的数据类型是因为,它是所有网络请求返回数据
 *类型的基类,可以更好的使用多态,也可以避免过多的对其他某种类型的依赖
 */

typedef NSURLSessionTask XZURLSessionTask;
typedef void(^XZResponseSuccess)(id response);
typedef void(^XZResponseError)(NSError * error);


@interface XZNetWorkTools : NSObject

/**
 *  @author 晓
 *
 *  设置BaseURL
 *
 *  @param baseURL
 */
+ (void)setBaseURL:(NSString *)baseURL;
+ (NSString *)baseURL;

/**
 *  @author 晓
 *
 *  设置超时时间
 *
 *  @param timeOut
 */
+(void)setTimeOut:(NSTimeInterval)timeOut;

/**
 *  @author 晓
 *
 *  当网络无法连接的时候,是否从本地缓存获取数据,默认是NO
 *
 *  @param shouldObtain BOOL值,
 */
+(void)obtainDataFromCacheWhenNetWorkUnConnect:(BOOL)shouldObtain;

/**
 *  @author 晓
 *
 *  是否缓存数据,默认缓存
 *
 *  @param isCacheGet  是否缓存GET的数据
 *  @param isCachePost 是否缓存POST的数据
 */
+(void)cacheGetRequest:(BOOL)isCacheGet cachePostRequest:(BOOL)isCachePost;


/**
 *  @author 晓
 *
 *  配置请求格式和响应格式
 *
 *  @param requestType      请求格式
 *  @param responseType     响应格式
 *  @param shouldAutoEncode 是否自动对URL地址进行编码
 *  @param shouldCallBack   取消请求的时候是否回调
 */
+(void)ocnfigRequestType:(XZRequestType)requestType
                responseType:(XZResponseType)responseType
        shouldAutoEncodeURL:(BOOL)shouldAutoEncode
    shouldCallBackOnCancelRequest:(BOOL)shouldCallBack;

/**
 *  @author 晓
 *
 *  配置只会请求一次公共请求头
 *
 *  @param headers 请求头
 */
+(void)configCommonRequestHttpHeaders:(NSDictionary *)headers;

/**
 *  @author 晓
 *
 *  根据URL地址取消请求
 *
 *  @param URL URL地址
 */
+(void)cancelRequestWithURL:(NSString *)URL;

/**
 *  @author 晓
 *
 *  取消所有的请求
 */
+(void)cancelAllRequest;

/**
 *  @author 晓
 *
 *  普通的get网络请求
 *
 *  @param url     请求地址
 *  @param success 成功回调
 *  @param error   失败回调
 *
 *  @return 返回请求到的数据
 */
+(XZURLSessionTask *)getWithURL:(NSString *)url success:(XZResponseSuccess)success failure:(XZResponseError)error;

//get请求带是否刷新缓存的参数
+(XZURLSessionTask *)getWithURL:(NSString *)url refreshCache:(BOOL)refreshCache success:(XZResponseSuccess)success failure:(XZResponseError)error;

//带参数的get请求
+(XZURLSessionTask *)getWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params success:(XZResponseSuccess)success failure:(XZResponseError)error;

//带进度的get请求
+(XZURLSessionTask *)getWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params progress:(XZGetDownloadProgress)progress success:(XZResponseSuccess)success failure:(XZResponseError)error;

/**
 *  @author 晓
 *
 *  post的请求
 *
 *  @param url          请求地址
 *  @param refreshCache 是否刷新缓存
 *  @param params       参数
 *  @param success      成功回调
 *  @param error        错误回调
 *
 *  @return 返回请求到的数据
 */
+(XZURLSessionTask *)postWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params success:(XZResponseSuccess)success failure:(XZResponseError)error;

//带进度的post请求
+(XZURLSessionTask *)postWithURL:(NSString *)url refreshCache:(BOOL)refreshCache params:(NSDictionary *)params progress:(XZPostDownloadProgress)progress success:(XZResponseSuccess)success failure:(XZResponseError)error;

/**
 *  @author 晓
*	图片上传接口，若不指定baseurl，可传完整的url
*
*	@param image			图片对象
*	@param url				上传图片的接口路径，如/path/images/
*	@param filename		给图片起一个名字，默认为当前日期时间,格式为"yyyyMMddHHmmss"，后缀为`jpg`
*	@param name				与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
*	@param mimeType		默认为image/jpeg
*	@param parameters	参数
*	@param progress		上传进度
*	@param success		上传成功回调
*	@param fail				上传失败回调
*
*	@return
*/
+ (XZURLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(XZUploadProgressBlocck)progress
                               success:(XZResponseSuccess)success
                                  fail:(XZResponseError)fail;


/**
 *  @author 晓
 *
 *	上传文件操作
 *
 *	@param url						上传路径
 *	@param uploadingFile	待上传文件的路径
 *	@param progress			上传进度
 *	@param success				上传成功回调
 *	@param fail					上传失败回调
 *
 *	@return
 */
+ (XZURLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(XZUploadProgressBlocck)progress
                                 success:(XZResponseSuccess)success
                                    fail:(XZResponseError)fail;


/**
 *  @author 晓
 *
 *  下载文件
 *
 *  @param url           下载URL
 *  @param saveToPath    下载到哪个路径下
 *  @param progressBlock 下载进度
 *  @param success       下载成功后的回调
 *  @param failure       下载失败后的回调
 */
+ (XZURLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(XZDownloadProgressBlocck)progressBlock
                               success:(XZResponseSuccess)success
                               failure:(XZResponseError)failure;

/**
 *  @author 晓
 *
 *  获取缓存的大小
 *
 *  @return 返回缓存的大小
 */
+(NSUInteger)totalCacheSize;

/**
 *  @author 晓
 *
 *  清理缓存
 */
+(void)clearCaches;

/**
 *  @author 晓
 *
 *  <#Description#>
 */


@end

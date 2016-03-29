//
//  CircleBannerView.h
//  CircleBannerView
//
//  Created by zhuochenming on 16/3/16.
//  Copyright (c) 2015年 zhuochenming. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CircleBannerView;

typedef NS_ENUM(NSInteger, CircleBannerViewScrollDirection) {
    CircleBannerViewScrollDirectionVertical,
    CircleBannerViewScrollDirectionHorizontal
};

@protocol CircleBannerViewDelegate <NSObject>

@optional
#warning 加载图片链接的代理，如果用的图片链接数组，必许实现该方法，你自己想 怎么加载 就怎么加载
- (void)imageView:(UIImageView *)imageView loadImageForUrl:(NSString *)url;

//轮播图滚动到哪一个item
- (void)bannerView:(CircleBannerView *)bannerView scrollToIndex:(NSInteger)index;

//点击回调
- (void)bannerView:(CircleBannerView *)bannerView didSelectAtIndex:(NSUInteger)index;

@end

@interface CircleBannerView : UIView

@property (nonatomic, assign) id<CircleBannerViewDelegate> delegate;

//自动换页时间间隔，0s 不自动滚动
@property (nonatomic, assign) NSTimeInterval interval;

//是否支持手势滑动，默认 YES
@property (nonatomic, assign, getter=isScrollEnabled) BOOL scrollEnabled;

//滚动方向
@property (nonatomic, assign) CircleBannerViewScrollDirection scrollDirection;

//网络图片
- (instancetype)initWithFrame:(CGRect)frame urlArray:(NSArray *)urlArray;

//本地图片
- (instancetype)initWithFrame:(CGRect)frame imageArray:(NSArray *)imageArray;

@end

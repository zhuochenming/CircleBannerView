//
//  CircleBannerView.m
//  CircleBannerView
//
//  Created by zhuochenming on 16/3/16.
//  Copyright (c) 2016年 zhuochenming. All rights reserved.
//

#import "CircleBannerView.h"
#import <objc/runtime.h>

static char TimerKey;

@interface CircleBannerCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation CircleBannerCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] init];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_imageView];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_imageView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_imageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_imageView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_imageView)]];
    }
    return self;
}

@end

@interface CircleBannerView ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) BOOL isURL;

@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, strong) UICollectionView *bannerCollectionView;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation CircleBannerView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame urlArray:(NSArray *)urlArray {
    self = [super initWithFrame:frame];
    if (self) {
        _isURL = YES;
        [self initSubviews];
        [self bannerWithURLArray:urlArray];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame imageArray:(NSArray *)imageArray {
    self = [super initWithFrame:frame];
    if (self) {
        _isURL = NO;
        [self initSubviews];
        [self bannerWithImageArray:imageArray];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.flowLayout.itemSize = self.frame.size;
}

#pragma mark - 链接
- (void)bannerWithURLArray:(NSArray *)urlArray {
    self.dataArray = urlArray;
    self.pageControl.numberOfPages = urlArray.count;
    if (_dataArray.count > 0) {
        [self.bannerCollectionView reloadData];
    }
}

#pragma mark - 图片
- (void)bannerWithImageArray:(NSArray *)imageArray {
    self.dataArray = imageArray;
    self.pageControl.numberOfPages = imageArray.count;
    if (_dataArray.count > 0) {
        [self.bannerCollectionView reloadData];
    }
}

#pragma mark - 加载视图
- (void)initSubviews {
    [self addSubview:self.bannerCollectionView];
    [self addSubview:self.pageControl];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_bannerCollectionView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_bannerCollectionView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_bannerCollectionView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_bannerCollectionView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_pageControl]-10-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_pageControl)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_pageControl]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_pageControl)]];
    self.scrollEnabled = YES;
    self.interval = 0.0;
    self.scrollDirection = CircleBannerViewScrollDirectionHorizontal;
}

#pragma mark - 计时器
- (void)addTimer {
    if (self.interval == 0) {
        return;
    }
    __block CircleBannerView *weakSelf = self;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    
    objc_setAssociatedObject(self, &TimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, _interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_source_set_event_handler(timer, ^{
            [weakSelf changePage];
        });
    });

    dispatch_resume(timer);
}

- (void)removeTimer {
    dispatch_source_t timer = objc_getAssociatedObject(self, &TimerKey);
    if (timer) {
        objc_setAssociatedObject(self, &TimerKey, nil, OBJC_ASSOCIATION_ASSIGN);
        dispatch_source_cancel(timer);
        timer = nil;
    }
}

- (void)changePage {
    CGFloat newOffSetLength = [self offsetX] + [self collectionViewWidth];
    //在换页到最后一个的时候多加一点距离，触发回到第一个图片的事件
    if (newOffSetLength == [self contentWidth] - [self collectionViewWidth]) {
        newOffSetLength += 1;
    }
    CGPoint offSet;
    if (self.scrollDirection == CircleBannerViewScrollDirectionHorizontal) {
       offSet = CGPointMake(newOffSetLength, 0);
    } else {
        offSet = CGPointMake(0, newOffSetLength);
    }
    [self.bannerCollectionView setContentOffset:offSet animated:YES];
}

#pragma mark - collectionView代理
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self removeTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.pageControl.currentPage = [self offsetX] / [self collectionViewWidth];
    [self addTimer];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UICollectionView *collectionView = (UICollectionView *)scrollView;
    if ([self offsetX] < 0) {
        [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_dataArray.count inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    } else if ([self offsetX] > [self contentWidth] - [self collectionViewWidth]) {
        [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    }
    
    if ([self offsetX] > (_dataArray.count - 1) * [self collectionViewWidth]) {
        self.pageControl.currentPage = 0;
    } else {
        self.pageControl.currentPage = [self offsetX] / [self collectionViewWidth];
    }
    
    if ([self.delegate respondsToSelector:@selector(bannerView:scrollToIndex:)]) {
        [self.delegate bannerView:self scrollToIndex:_pageControl.currentPage];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _dataArray.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CircleBannerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"banner" forIndexPath:indexPath];
    if (_isURL) {
        NSString *url;
        if (indexPath.row == _dataArray.count) {
            url = _dataArray.firstObject;
        } else {
            url = _dataArray[indexPath.row];
        }
        if ([self.delegate respondsToSelector:@selector(imageView:loadImageForUrl:)]) {
            [self.delegate imageView:cell.imageView loadImageForUrl:url];
        }
    } else {
        NSInteger row;
        if (indexPath.row == _dataArray.count){
            row = 0;
        } else {
            row = indexPath.row;
        }
        cell.imageView.image = _dataArray[row];
    }
   
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(bannerView:didSelectAtIndex:)]) {
        [self.delegate bannerView:self didSelectAtIndex:_pageControl.currentPage];
    }
}

#pragma mark - setter方法
- (void)setScrollDirection:(CircleBannerViewScrollDirection)scrollDirection {
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        if (scrollDirection == CircleBannerViewScrollDirectionVertical) {
            self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        } else {
            self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
        [self.bannerCollectionView reloadData];
    }
}

- (void)setInterval:(NSTimeInterval)interval {
    _interval = interval;
    [self removeTimer];
    if (interval != 0) {
        [self addTimer];
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    self.bannerCollectionView.scrollEnabled = _scrollEnabled;
}

#pragma mark - getter方法
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc]init];
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.minimumLineSpacing = 0;
    }
    return _flowLayout;
}

- (UICollectionView *)bannerCollectionView {
    if (!_bannerCollectionView) {
        _bannerCollectionView = [[UICollectionView alloc]initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
        _bannerCollectionView.dataSource = self;
        _bannerCollectionView.delegate = self;
        _bannerCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_bannerCollectionView registerClass:[CircleBannerCell class] forCellWithReuseIdentifier:@"banner"];
        _bannerCollectionView.pagingEnabled = YES;
        _bannerCollectionView.showsHorizontalScrollIndicator = NO;
        _bannerCollectionView.showsVerticalScrollIndicator = NO;
    }
    return _bannerCollectionView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPage = 0;
        _pageControl.numberOfPages = _dataArray.count;
        _pageControl.backgroundColor = [UIColor clearColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return  _pageControl;
}

#pragma mark - 大小，偏移
- (CGFloat)collectionViewWidth {
    return self.scrollDirection == CircleBannerViewScrollDirectionHorizontal ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
}

- (CGFloat)offsetX {
    return self.scrollDirection == CircleBannerViewScrollDirectionHorizontal ? self.bannerCollectionView.contentOffset.x : self.bannerCollectionView.contentOffset.y;
}

- (CGFloat)contentWidth {
    return self.scrollDirection == CircleBannerViewScrollDirectionHorizontal ? self.bannerCollectionView.contentSize.width : self.bannerCollectionView.contentSize.height;
}

@end

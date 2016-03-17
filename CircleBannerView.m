//
//  CircleBannerView.m
//  CircleBannerView
//
//  Created by zhuochenming on 16/3/16.
//  Copyright (c) 2016年 zhuochenming. All rights reserved.
//

#import "CircleBannerView.h"

@interface CircleBannerCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation CircleBannerCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc]init];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:self.imageView];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_imageView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_imageView)]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_imageView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_imageView)]];
    }
    return self;
}

@end

@interface CircleBannerView ()<UIScrollViewDelegate, UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *urlArray;

@property (nonatomic, strong) UICollectionView *bannerCollectionView;

@property (nonatomic, strong) UIPageControl *pageController;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, assign) CGFloat unitLength;

@property (nonatomic, assign) CGFloat offsetLength;

@property (nonatomic, assign) CGFloat contentLength;

@property (nonatomic, assign) CGFloat oldOffsetLength;

@end

@implementation CircleBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.flowLayout.itemSize = self.frame.size;
}

#pragma mark - public method
- (void)circleBannerWithURLArray:(NSArray *)urlArray {
    self.urlArray = urlArray;
    self.pageController.numberOfPages = urlArray.count;
    [self.bannerCollectionView reloadData];
}

#pragma mark - private method
- (void)initSubviews {
    [self addSubview:self.bannerCollectionView];
    [self addSubview:self.pageController];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_bannerCollectionView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_bannerCollectionView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_bannerCollectionView]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_bannerCollectionView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_pageController]-10-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_pageController)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_pageController]-0-|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_pageController)]];
    self.scrollEnabled = YES;
    self.interval = 0.0;
    self.scrollDirection = CircleBannerViewScrollDirectionHorizontal;
}

- (void)addTimer {
    if (self.interval == 0) {
        return;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(changePage) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)removeTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)changePage {
    
    CGFloat newOffSetLength = self.offsetLength + self.unitLength;
    //在换页到最后一个的时候多加一点距离，触发回到第一个图片的事件
    if (newOffSetLength == self.contentLength - self.unitLength) {
        newOffSetLength += 1;
    }
    CGPoint offSet;
    if (self.scrollDirection == CircleBannerViewScrollDirectionHorizontal) {
       offSet = CGPointMake(newOffSetLength, 0);
    }else{
        offSet = CGPointMake(0,newOffSetLength);
    }
    [self.bannerCollectionView setContentOffset:offSet animated:YES];
    
}

- (NSString *)getImageUrlForIndexPath:(NSIndexPath *)indexPath {
    if (!(self.urlArray.count > 0)) {
        return nil;
    }
    if (indexPath.row == self.urlArray.count){
        return self.urlArray.firstObject;
    } else {
        return self.urlArray[indexPath.row];
    }
}

#pragma mark - collectionView delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.urlArray.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CircleBannerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"banner" forIndexPath:indexPath];
    NSString *url = [self getImageUrlForIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(imageView:loadImageForUrl:)]) {
        [self.delegate imageView:cell.imageView loadImageForUrl:url];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(bannerView:didSelectAtIndex:)]) {
        [self.delegate bannerView:self didSelectAtIndex:self.pageController.currentPage];
    }
}

#pragma mark - scrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_timer invalidate];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.pageController.currentPage = self.offsetLength / self.unitLength;
    [self addTimer];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UICollectionView *collectionView = (UICollectionView *)scrollView;
    if (self.oldOffsetLength > self.offsetLength) {
        if (self.offsetLength < 0)
        {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.urlArray.count inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    }else{
        if (self.offsetLength > self.contentLength - self.unitLength) {
            [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        }
    }
    self.pageController.currentPage = self.offsetLength / self.unitLength;
    self.oldOffsetLength = self.offsetLength;
}

#pragma mark - setter && getter
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

- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc]init];
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.minimumLineSpacing = 0;
    }
    return _flowLayout;
}

- (UIPageControl *)pageController {
    if (!_pageController) {
        _pageController = [[UIPageControl alloc] init];
        _pageController.currentPage = 0;
        _pageController.numberOfPages = self.urlArray.count;
        _pageController.backgroundColor = [UIColor clearColor];
        _pageController.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageController.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageController.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return  _pageController;
}

- (void)setScrollDirection:(CircleBannerViewScrollDirection)scrollDirection {
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        if (scrollDirection == CircleBannerViewScrollDirectionVertical) {
            self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        }else{
           self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
        [self.bannerCollectionView reloadData];
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    self.bannerCollectionView.scrollEnabled = _scrollEnabled;
}

- (CGFloat)unitLength {
    return self.scrollDirection == CircleBannerViewScrollDirectionHorizontal ? CGRectGetWidth(self.frame) : CGRectGetHeight(self.frame);
}

- (CGFloat)offsetLength {
    return self.scrollDirection == CircleBannerViewScrollDirectionHorizontal ? self.bannerCollectionView.contentOffset.x : self.bannerCollectionView.contentOffset.y;
}

- (CGFloat)contentLength {
    return self.scrollDirection == CircleBannerViewScrollDirectionHorizontal ? self.bannerCollectionView.contentSize.width : self.bannerCollectionView.contentSize.height;
}
- (void)setInterval:(NSTimeInterval)interval {
    _interval = interval;
    [self removeTimer];
    if (interval != 0) {
        [self addTimer];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

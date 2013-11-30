//
//  PhotoAlbumLayout.m
//  PhotoCopy
//
//  Created by Bradley Bergeron on 8/15/13.
//  Copyright (c) 2013 Bradley Bergeron. All rights reserved.
//
//  Modified from http://blog.radi.ws/post/32905838158/sticky-headers-for-uicollectionview-using THANKS!
//

#import "PhotoAlbumLayout.h"


#pragma mark -
@implementation PhotoAlbumLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *answer = [[super layoutAttributesForElementsInRect:rect] mutableCopy];

    NSMutableIndexSet *missingSections = [NSMutableIndexSet indexSet];

    for (NSUInteger idx = 0; idx < [answer count]; idx++)
    {
        UICollectionViewLayoutAttributes *layoutAttributes = answer[idx];

        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell)
            [missingSections addIndex:layoutAttributes.indexPath.section];

        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader])
        {
            [answer removeObjectAtIndex:idx];
            idx--;
        }
    }

    [missingSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
        [answer addObject:layoutAttributes];
    }];

    return answer;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        UICollectionView * const cv = self.collectionView;
        CGPoint const contentOffset = cv.contentOffset;
        CGPoint nextHeaderOrigin = CGPointMake(INFINITY, INFINITY);

        if (indexPath.section+1 < [cv numberOfSections])
        {
            UICollectionViewLayoutAttributes *nextHeaderAttributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section + 1]];
            nextHeaderOrigin = nextHeaderAttributes.frame.origin;
        }

        CGRect frame = attributes.frame;
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical)
            frame.origin.y = MIN(MAX(contentOffset.y, frame.origin.y), nextHeaderOrigin.y - CGRectGetHeight(frame));
        else
            frame.origin.x = MIN(MAX(contentOffset.x, frame.origin.x), nextHeaderOrigin.x - CGRectGetWidth(frame));
        attributes.zIndex = 1024;
        attributes.frame = frame;
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBound
{
    return YES;
}

@end

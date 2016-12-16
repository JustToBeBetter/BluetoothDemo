//
//  ShoppingViewController.m
//  BlueToochDemo
//
//  Created by Harvey on 16/4/26.
//  Copyright © 2016年 Halley. All rights reserved.
//

#import "ShoppingViewController.h"

@interface ShoppingViewController ()


@property (strong, nonatomic)   NSArray            *goodsArray;  /**< 商品数组 */

@end

@implementation ShoppingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"购物车";
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(printAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    NSDictionary *dict1 = @{@"name":@"铅笔",@"amount":@"5",@"price":@"2.0"};
    NSDictionary *dict2 = @{@"name":@"橡皮",@"amount":@"1",@"price":@"1.0"};
    NSDictionary *dict3 = @{@"name":@"笔记本",@"amount":@"3",@"price":@"3.0"};
    self.goodsArray = @[dict1, dict2, dict3];
}

- (HLPrinter *)getPrinter
{
    
    HLPrinter *printer = [[HLPrinter alloc] init];
    NSString *title = @"开衫";
    [printer appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
    // 二维码
    //位图方式打印二维码
    [printer appendQRCodeWithInfo:@"www.baidu.com"];
    //指令方式打印二维码
    //[printer appendQRCodeWithInfo:@"www.baidu.com" size:12];

    // 图片
    [printer appendImage:[UIImage imageNamed:@"ico180"] alignment:HLTextAlignmentLeft maxWidth:300];
    [printer appendText:@"JNG4249565104102" alignment:HLTextAlignmentCenter];
    [printer appendText:@"大红，M 2237038" alignment:HLTextAlignmentCenter];
    return printer;
}

- (void)printAction
{
    [self.navigationController popViewControllerAnimated:YES];
    
    HLPrinter *printInfo = [self getPrinter];
    
    if (_printBlock) {
        _printBlock(printInfo);
    }
}




@end

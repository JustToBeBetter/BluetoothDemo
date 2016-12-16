//
//  ViewController.m
//  BluetoothDemo
//
//  Created by DBOX on 2016/10/25.
//  Copyright © 2016年 DBOX. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEDetailViewController.h"

#import "HLBLEManager.h"
#import "SVProgressHUD.h"
#import "SEPrinterManager.h"
#define kScreenSize  [UIScreen mainScreen].bounds.size
#define kScreenWidth  kScreenSize.width
#define kScreenHeight kScreenSize.height

@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate,UITableViewDelegate,UITableViewDataSource>
{
   // UITableView *_tableView;
    NSMutableArray *_deviceArray;
    
    
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//@property (nonatomic,strong) UITableView  *tableView;

@property (strong, nonatomic)   NSMutableArray              *deviceArray;
// 中心管理者
 @property (nonatomic, strong) CBCentralManager *cMgr;
 
 // 连接到的外设
 
 @property (nonatomic, strong) CBPeripheral *peripheral;
@end

@implementation ViewController

-(CBCentralManager *)cMgr
{
    if (!_cMgr) {
        _cMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _cMgr;
}
//只要中心管理者初始化 就会触发此代理方法 判断手机蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case 0:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case 1:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case 2:
            NSLog(@"CBCentralManagerStateUnsupported");//不支持蓝牙
            break;
        case 3:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case 4:
        {
            NSLog(@"CBCentralManagerStatePoweredOff");//蓝牙未开启
        }
            break;
        case 5:
        {
            NSLog(@"CBCentralManagerStatePoweredOn");//蓝牙已开启
            // 在中心管理者成功开启后再进行一些操作
            // 搜索外设
            [self.cMgr scanForPeripheralsWithServices:nil // 通过某些服务筛选外设
                                              options:nil]; // dict,条件
            // 搜索成功之后,会调用我们找到外设的代理方法
            // - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设
        }
            break;
        default:
            break;
    }
}
// 发现外设后调用的方法
- (void)centralManager:(CBCentralManager *)central // 中心管理者
 didDiscoverPeripheral:(CBPeripheral *)peripheral // 外设
     advertisementData:(NSDictionary *)advertisementData // 外设携带的数据
                  RSSI:(NSNumber *)RSSI // 外设发出的蓝牙信号强度
{
    //NSLog(@"%s, line = %d, cetral = %@,peripheral = %@, advertisementData = %@, RSSI = %@", __FUNCTION__, __LINE__, central, peripheral, advertisementData, RSSI);
    
    /*
     peripheral = , advertisementData = {
     kCBAdvDataChannel = 38;
     kCBAdvDataIsConnectable = 1;
     kCBAdvDataLocalName = OBand;
     kCBAdvDataManufacturerData = <4c69616e 0e060678 a5043853 75>;
     kCBAdvDataServiceUUIDs =     (
     FEE7
     );
     kCBAdvDataTxPowerLevel = 0;
     }, RSSI = -55
     根据打印结果,我们可以得到运动手环它的名字叫 OBand-75
     
     */
    
    // 需要对连接到的外设进行过滤
    // 1.信号强度(40以上才连接, 80以上连接)
    // 2.通过设备名(设备字符串前缀是 OBand)
    // 在此时我们的过滤规则是:有OBand前缀并且信号强度大于35
    // 通过打印,我们知道RSSI一般是带-的
    
    if ([peripheral.name hasPrefix:@"OBand"]) {
        // 在此处对我们的 advertisementData(外设携带的广播数据) 进行一些处理
        
        // 通常通过过滤,我们会得到一些外设,然后将外设储存到我们的可变数组中,
        // 这里由于附近只有1个运动手环, 所以我们先按1个外设进行处理
        
        // 标记我们的外设,让他的生命周期 = vc
        self.peripheral = peripheral;
        // 发现完之后就是进行连接
        [self.cMgr connectPeripheral:self.peripheral options:nil];
        NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    }
}
//3.连接外围设备

// 中心管理者连接外设成功
- (void)centralManager:(CBCentralManager *)central // 中心管理者
  didConnectPeripheral:(CBPeripheral *)peripheral // 外设
{
    NSLog(@"%s, line = %d, %@=连接成功", __FUNCTION__, __LINE__, peripheral.name);
    // 连接成功之后,可以进行服务和特征的发现
    
    //  设置外设的代理
    self.peripheral.delegate = self;
    
    // 外设发现服务,传nil代表不过滤
    // 这里会触发外设的代理方法 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [self.peripheral discoverServices:nil];
}
// 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
}

// 丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
}

//4.获得外围设备的服务 & 5.获得服务的特征

// 发现外设服务里的特征的时候调用的代理方法(这个是比较重要的方法，你在这里可以通过事先知道UUID找到你需要的特征，订阅特征，或者这里写入数据给特征也可以)
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    for (CBCharacteristic *cha in service.characteristics) {
        NSLog(@"%s, line = %d, char = %@", __FUNCTION__, __LINE__, cha);
        
    }
}

//6.从外围设备读数据

// 更新特征的value的时候会调用 （凡是从蓝牙传过来的数据都要经过这个回调，简单的说这个方法就是你拿数据的唯一方法） 你可以判断是否
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    if ([characteristic  isEqual: @"你要的特征的UUID或者是你已经找到的特征"]) {
        //characteristic.value就是你要的数据
    }
}

//7.给外围设备发送数据（也就是写入数据到蓝牙）
//这个方法你可以放在button的响应里面，也可以在找到特征的时候就写入，具体看你业务需求怎么用啦

//[self.peripherale writeValue:_batteryData forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];//第一个参数是已连接的蓝牙设备 ；第二个参数是要写入到哪个特征； 第三个参数是通过此响应记录是否成功写入

// 需要注意的是特征的属性是否支持写数据
- (void)yf_peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast                                                = 0x01,
     CBCharacteristicPropertyRead                                                    = 0x02,
     CBCharacteristicPropertyWriteWithoutResponse                                    = 0x04,
     CBCharacteristicPropertyWrite                                                    = 0x08,
     CBCharacteristicPropertyNotify                                                    = 0x10,
     CBCharacteristicPropertyIndicate                                                = 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites                                = 0x40,
     CBCharacteristicPropertyExtendedProperties                                        = 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)        = 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)    = 0x200
     };
     
     打印出特征的权限(characteristic.properties),可以看到有很多种,这是一个NS_OPTIONS的枚举,可以是多个值
     常见的又read,write,noitfy,indicate.知道这几个基本够用了,前俩是读写权限,后俩都是通知,俩不同的通知方式
     */
    //    NSLog(@"%s, line = %d, char.pro = %d", __FUNCTION__, __LINE__, characteristic.properties);
    // 此时由于枚举属性是NS_OPTIONS,所以一个枚举可能对应多个类型,所以判断不能用 = ,而应该用包含&
}

#pragma
#pragma  mark =================lalala=================
- (NSArray *)printDataArray{
    NSMutableArray *printInfoArray = [NSMutableArray array];
    HLPrinter *printer = [[HLPrinter alloc] init];
    NSString *str1 = @"测试电";
    [printer appendText:str1 alignment:HLTextAlignmentCenter];
    
    NSData *data1 = [printer getFinalData];
    [printInfoArray addObject:data1];
    
    printer = [[HLPrinter alloc] init];
    [printer appendImage:[UIImage imageNamed:@"110"] alignment:HLTextAlignmentLeft maxWidth:100];
    NSData *data2 = [printer getFinalData];
    [printInfoArray addObject:data2];
    
    
    // 你可以多行数据一起写进蓝牙，但是不要过长，否则可能会导致乱码
    //    HLPrinter *printer = [[HLPrinter alloc] init];
    //    NSString *title = @"测试电商";
    //    [printer appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
    //    NSData *data1 = [printer getFinalData];
    //    [printInfoArray addObject:data1];
    
    // 1.多行数组组合后打印
    //printer = [[HLPrinter alloc] init];
    //    [printer appendTitle:@"时间:" value:@"2016-04-27 10:01:50" valueOffset:150];
    //    [printer appendText:@"地址:深圳市南山区学府路东深大店" alignment:HLTextAlignmentLeft];
    //    data1 = [printer getFinalData];
    //    [printInfoArray addObject:data1];
    
    // 2.单行数据打印
    //    printer = [[HLPrinter alloc] init];
    //    [printer appendSeperatorLine];
    //    data1 = [printer getFinalData];
    //   [printInfoArray addObject:data1];
    //
    //    printer = [[HLPrinter alloc] init];
    //   [printer appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
    //   data1 = [printer getFinalData];
    //    [printInfoArray addObject:data1];
   
    
    return printInfoArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"未连接";
    SEPrinterManager *_manager = [SEPrinterManager sharedInstance];
    [_manager startScanPerpheralTimeout:10 Success:^(NSArray<CBPeripheral *> *perpherals,BOOL isTimeout) {
        NSLog(@"perpherals:%@",perpherals);
        _deviceArray = perpherals;
        [_tableView reloadData];
    } failure:^(SEScanError error) {
        NSLog(@"error:%ld",(long)error);
    }];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"打印" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    //[self initFooter];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //    if ([SEPrinterManager sharedInstance].connectedPerpheral) {
    //        self.title = [SEPrinterManager sharedInstance].connectedPerpheral.name;
    //    } else {
    //        [[SEPrinterManager sharedInstance] autoConnectLastPeripheralTimeout:10 completion:^(CBPeripheral *perpheral, NSError *error) {
    //            NSLog(@"自动重连返回");
    //            self.title = [SEPrinterManager sharedInstance].connectedPerpheral.name;
    // 因为自动重连后，特性还没扫描完，所以延迟一会开始写入数据
    //            [self performSelector:@selector(rightAction) withObject:nil afterDelay:1.0];
    //        }];
    //    }
}
- (void)initFooter{
    
    UIView *footer = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth)];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 20, kScreenWidth, kScreenWidth)];
    [footer addSubview:imageView];
    //UIImage *img = [UIImage qrCodeImageWithInfo:@"www.baidu.com" centerImage:nil width:150];
    //imageView.image = img;
  //  self.tableView.tableFooterView = footer;
    
    UIView *pView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth)];
    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 20)];
    title.text = @"测试测试测试";
    title.textAlignment = NSTextAlignmentCenter;
    [pView addSubview:title];
    
    UIImageView *pic = [[UIImageView alloc]initWithFrame:CGRectMake(20, 30, kScreenWidth/2 - 40, kScreenWidth/2 - 40)];
    pic.image = [UIImage imageNamed:@"110"];
    [pView addSubview:pic];
    
    UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(pic.frame), 30, kScreenWidth/2 - 40, kScreenWidth/2 - 40)];
    [pView addSubview:imageView1];
    UIImage *img1 = [UIImage qrCodeImageWithInfo:@"www.baidu.com" centerImage:nil width:150];
    imageView1.image = img1;
    
    UILabel *snLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView1.frame), kScreenWidth, 20)];
    snLabel.text = @"RN3456789012";
    snLabel.textAlignment = NSTextAlignmentCenter;
    [pView addSubview:snLabel];
    
    UILabel *infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(snLabel.frame), kScreenWidth, 20)];
    infoLabel.text = @"红色 XXL 732874293";
    infoLabel.textAlignment = NSTextAlignmentCenter;
    [pView addSubview:infoLabel];
    
    imageView.image = [self getImageFromView:pView];
    
    
    
    UIImageView *pic1 = [[UIImageView alloc]initWithFrame:CGRectMake(200, 20, 150, 150)];
    [footer addSubview:pic1];
    UIImage *image1 = [UIImage imageNamed:@"ico180"];
    UIImage *newImage = [image1 imageWithscaleMaxWidth:150];
    newImage = [newImage blackAndWhiteImage];
    NSData *imageData = [newImage bitmapData];
    
    NSLog(@"imageData=%@",imageData);
    
    //    pic.image = [UIImage imageWithData:imageData];
    
    UIImage *image = [UIImage imageNamed:@"110.png"];
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *rawData = (unsigned char*) calloc(height*width*4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel* width;
    NSUInteger bitsPerComponent = 8;
    //this methid returns the pixel data in rawData
    CGContextRef context = CGBitmapContextCreate(rawData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0,0, width,height), imageRef);
    CGContextRelease(context);
    
    size_t length = image.size.height*image.size.width*4;
    CGFloat intensity;
    
    //black or white
    int bw;
    
    //initialize print buffer
    size_t bufferLength = (image.size.height*image.size.width) / 8+10;
    unsigned char buffer[bufferLength];
    
    buffer[0] = 0x55; buffer[1] = 0x66; buffer[2] = 0x77; buffer[3] = 0x88; //esc sequence
    buffer[4] = 0x44; //print command
    buffer[5] = 0x1B; buffer[6] = 0x58; buffer[7] = 0x31;buffer[8] = (char) 200/8 ; buffer[9] = 30 ;  //and iOS specific print image command
    
    int pixelCount = 0;
    int byteCount = 10;
    
    
    //check pixel values and average to black or white (4 bytes per pixel)
    for(int index = 0; index<length;index+=4){
        intensity = (float)(rawData[index]+rawData [index+1] + rawData[index+2])/3.;
        
        if(intensity >= 128 ){
            bw = 255;
            //if pixel white, bit is 0
            
        }
        else {
            bw = 0;
            //if black pixel, set one bit of byte on
            buffer[byteCount] += (char) pow(2, 7 - pixelCount);
            
        }
        
        //next pixel
        pixelCount++;
        
        //every 8 pixels, move to next char of print buffer
        if(pixelCount % 8 == 0)
            byteCount++;
        
        
        
        //      NSLog(@"Pixel %i : r: %i g: %i b: %i a: %i", counter++, rawData[index], rawData[index+1], rawData[index+2], rawData[index+3]);
        
        //save pixel values as black or white for new image
        rawData[index]   = bw;
        rawData[index+1] = bw;
        rawData[index+2] = bw;
        rawData[index+3] = 255;
    }
    
    
    CGContextRef bitmapContext=CGBitmapContextCreate(rawData, image.size.width, image.size.height, 8, 4*image.size.width, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CFRelease(colorSpace);
    
    free(rawData);
    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    
    UIImage *bwImage = [UIImage imageWithCGImage:cgImage];
    NSLog(@"data=%@",bwImage);
    
    //          NSLog(@"2011printing imagelog");
    //      //[self addLabel:@"buffer3 is selected"];
    //      [[session outputStream] writ
}
-(UIImage *)getImageFromView:(UIView *)theView

{
    
    //UIGraphicsBeginImageContext(theView.bounds.size);
    
    UIGraphicsBeginImageContextWithOptions(theView.bounds.size, NO, theView.layer.contentsScale);
    
    [theView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image=UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
    
}
- (HLPrinter *)getPrinter
{
    HLPrinter *printer = [[HLPrinter alloc] init];
    
    
//    UIView *pView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth - 40)];
//    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth, 20)];
//    title.text = @"测试测试测试";
//    title.textAlignment = NSTextAlignmentCenter;
//    [pView addSubview:title];
//    
//    UIImageView *pic = [[UIImageView alloc]initWithFrame:CGRectMake(20, 30, kScreenWidth/2 - 40, kScreenWidth/2 - 40)];
//    pic.image = [UIImage imageNamed:@"110"];
//    [pView addSubview:pic];
//    
//    UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMaxX(pic.frame), 30, kScreenWidth/2 - 40, kScreenWidth/2 - 40)];
//    [pView addSubview:imageView1];
//    UIImage *img1 = [UIImage qrCodeImageWithInfo:@"www.baidu.com" centerImage:nil width:150];
//    imageView1.image = img1;
//    UILabel *snLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView1.frame), kScreenWidth, 20)];
//    snLabel.text = @"RN3456789012";
//    snLabel.textAlignment = NSTextAlignmentCenter;
//    [pView addSubview:snLabel];
//    UILabel *infoLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(snLabel.frame), kScreenWidth, 20)];
//    infoLabel.text = @"红色 XXL 732874293";
//    infoLabel.textAlignment = NSTextAlignmentCenter;
//    [pView addSubview:infoLabel];
//    13966797801
//    [printer appendImage:[self getImageFromView:pView] alignment:HLTextAlignmentCenter maxWidth:400];
    
    NSString *title = @"测试电商";
    [printer appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
    //[printer appendLeftImage:[UIImage imageNamed:@"110"] maxWidth:250 RightQRInfo:@"www.baidu.com" size:4];
     [printer appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
    //TODO:指令打印二维码
    [printer appendQRCodeWithInfo:@"www.baidu.com" size:4];
    
    //TODO:打印图片
    [printer appendImage:[UIImage imageNamed:@"110"] alignment:HLTextAlignmentLeft maxWidth:250];

    //    [printer appendText:@"位图方式二维码" alignment:HLTextAlignmentCenter];
    //    [printer appendQRCodeWithInfo:@"www.baidu.com"];
    //
    //   [printer appendSeperatorLine];
    //    [printer appendText:@"指令方式二维码" alignment:HLTextAlignmentCenter];
    
    return printer;
}
- (NSArray *)getDataArrayWithData:(NSData *)data{
    
    NSInteger length = 60;
    NSMutableArray *dataArray = [[NSMutableArray alloc]init];
    NSInteger cout = data.length/length;
    
    for (int i = 0 ; i < cout; i ++) {
        NSData *subData = [data subdataWithRange:NSMakeRange(i*length, length)];
        [dataArray addObject:subData];
    }
    NSData *lastData = [data subdataWithRange:NSMakeRange(cout*length, data.length - cout*length)];
    [dataArray addObject:lastData];
    return dataArray;
}
- (void)rightAction
{
#if 1
    //方式一：
    HLPrinter *printer = [self getPrinter];
    
    NSData *mainData = [printer getFinalData];
    NSLog(@"senddatalenth=%ld",mainData.length);
    
    NSArray *dataArray = [self getDataArrayWithData:mainData];

    for (int i = 0; i < dataArray.count; i ++) {
        NSData *sendData = dataArray[i];
        [[SEPrinterManager sharedInstance] sendPrintData:sendData completion:^(CBPeripheral *connectPerpheral, BOOL completion, NSString *error) {
            NSLog(@"写入结：%d---错误:%@",completion,error);
             //获取打印机单次接收的最大长度
            NSLog(@"lenth=%ld",[connectPerpheral maximumWriteValueLengthForType:1]);
            
        }];
    }
    
#else
#warning 如果你用方式一和方式二打印出现乱码，说明打印机不支持大数据打印，需要分开来打印
    NSArray *printArray = [self printDataArray];
    for (NSData *printData in printArray) {
        [[SEPrinterManager sharedInstance] sendPrintData:printData completion:^(CBPeripheral *connectPerpheral, BOOL completion, NSString *error) {
            if (!error) {
                NSLog(@"写入成功");
            }
        }];
    }
#endif
    //方式二：
    //     SEPrinterManager *_manager = [SEPrinterManager sharedInstance];
    //    [_manager prepareForPrinter];
    ////    [_manager appendText:title alignment:HLTextAlignmentCenter fontSize:HLFontSizeTitleBig];
    ////    [_manager appendText:str1 alignment:HLTextAlignmentCenter];
    //   [_manager appendBarCodeWithInfo:@"RN3456789012"];
    ////    [_manager appendSeperatorLine];
    //    [_manager appendSeperatorLine];
    //    [_manager appendLeftText:@"商品" middleText:@"数量" rightText:@"单价" isTitle:YES];
    //    [_manager appendFooter:nil];
    //   [_manager appendImage:[UIImage imageNamed:@"ico180"] alignment:HLTextAlignmentCenter maxWidth:300];
    //    [_manager printWithResult:nil];
    
}


//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view, typically from a nib.
//    _deviceArray = [[NSMutableArray alloc] init];
//    _tableView = [[UITableView alloc]initWithFrame:self.view.frame style:UITableViewStylePlain];
//    _tableView.delegate = self;
//    _tableView.dataSource = self;
//    _tableView.rowHeight = 60;
//   // [self.view addSubview:_tableView];
//
//    HLBLEManager *manager = [HLBLEManager sharedInstance];
//    __weak HLBLEManager *weakManager = manager;
//    manager.stateUpdateBlock = ^(CBCentralManager *central) {
//        NSString *info = nil;
//        switch (central.state) {
//            case CBCentralManagerStatePoweredOn:
//                info = @"蓝牙已打开，并且可用";
//                //三种种方式
//                // 方式1
//                [weakManager scanForPeripheralsWithServiceUUIDs:nil options:nil];
//                //                // 方式2
//                //                [central scanForPeripheralsWithServices:nil options:nil];
//                //                // 方式3
//                //                [weakManager scanForPeripheralsWithServiceUUIDs:nil options:nil didDiscoverPeripheral:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
//                //
//                //                }];
//                break;
//            case CBCentralManagerStatePoweredOff:
//                info = @"蓝牙可用，未打开";
//                break;
//            case CBCentralManagerStateUnsupported:
//                info = @"SDK不支持";
//                break;
//            case CBCentralManagerStateUnauthorized:
//                info = @"程序未授权";
//                break;
//            case CBCentralManagerStateResetting:
//                info = @"CBCentralManagerStateResetting";
//                break;
//            case CBCentralManagerStateUnknown:
//                info = @"CBCentralManagerStateUnknown";
//                break;
//        }
//        
//        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
//        [SVProgressHUD showInfoWithStatus:info ];
//    };
//    
//    manager.discoverPeripheralBlcok = ^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
//        if (peripheral.name.length <= 0) {
//            return ;
//        }
//        
//        if (self.deviceArray.count == 0) {
//            NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
//            [self.deviceArray addObject:dict];
//        } else {
//            BOOL isExist = NO;
//            for (int i = 0; i < self.deviceArray.count; i++) {
//                NSDictionary *dict = [self.deviceArray objectAtIndex:i];
//                CBPeripheral *per = dict[@"peripheral"];
//                if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
//                    isExist = YES;
//                    NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
//                    [_deviceArray replaceObjectAtIndex:i withObject:dict];
//                }
//            }
//            
//            if (!isExist) {
//                NSDictionary *dict = @{@"peripheral":peripheral, @"RSSI":RSSI};
//                [self.deviceArray addObject:dict];
//            }
//        }
//        
//        [self.tableView reloadData];
//        
//    };
//
//}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _deviceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"deviceId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    CBPeripheral *peripherral = [self.deviceArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"名称:%@",peripherral.name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CBPeripheral *peripheral = [self.deviceArray objectAtIndex:indexPath.row];
    
    [[SEPrinterManager sharedInstance] connectPeripheral:peripheral completion:^(CBPeripheral *perpheral, NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:@"连接失败"];
        } else {
            self.title = @"已连接";
            [SVProgressHUD showSuccessWithStatus:@"连接成功"];
        }
    }];
    
    // 如果你需要连接，立刻去打印
    //    [[SEPrinterManager sharedInstance] fullOptionPeripheral:peripheral completion:^(SEOptionStage stage, CBPeripheral *perpheral, NSError *error) {
    //        if (stage == SEOptionStageSeekCharacteristics) {
    //            HLPrinter *printer = [self getPrinter];
    //
    //            NSData *mainData = [printer getFinalData];
    //            [[SEPrinterManager sharedInstance] sendPrintData:mainData completion:nil];
    //        }
    //    }];
}

//#pragma mark - UITableViewDataSource
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    return _deviceArray.count;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *identifier = @"deviceId";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
//    }
//    
//    NSDictionary *dict = [self.deviceArray objectAtIndex:indexPath.row];
//    CBPeripheral *peripherral = dict[@"peripheral"];
//    cell.textLabel.text = [NSString stringWithFormat:@"名称:%@",peripherral.name];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"信号强度:%@",dict[@"RSSI"]];
//    if (peripherral.state == CBPeripheralStateConnected) {
//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
//    } else {
//        cell.accessoryType = UITableViewCellAccessoryNone;
//    }
//    
//    return cell;
//}
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    NSDictionary *dict = [self.deviceArray objectAtIndex:indexPath.row];
//    CBPeripheral *peripheral = dict[@"peripheral"];
//    
//    BLEDetailViewController *detailVC = [[BLEDetailViewController alloc]init];
//    detailVC.perpheral = peripheral;
//    [self.navigationController pushViewController:detailVC animated:YES];
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

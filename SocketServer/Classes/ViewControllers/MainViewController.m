//
//  MainViewController.m
//  SocketServer
//
//  Created by 李文龙 on 15/9/26.
//  Copyright (c) 2015年 李文龙. All rights reserved.
//

#import "MainViewController.h"
#import <CocoaAsyncSocket/CocoaAsyncSocket.h>

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    UITextField * _textField;
    dispatch_queue_t _socketQueue;
    
    GCDAsyncSocket *_listenSocket;
    NSMutableArray *_connectedSockets;
    UIButton * _rightBtn;
    BOOL isRunning;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MainViewController

#pragma mark - Private Method

- (void)initDatas
{
    self.title = [[UIDevice currentDevice]iPAddress];
    _socketQueue = dispatch_queue_create("socketQueue", NULL);
    
    _listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
    
    // Setup an array to store all accepted client connections
    _connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
    
    isRunning = NO;
}

- (void)initViews
{
    _textField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, 80, 30)];
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.placeholder = @"端口号";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:_textField];
    _rightBtn = [self createRightItemAction:@selector(rightBtnCLick:)];
    _rightBtn.width = 70;
    [_rightBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [_rightBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_rightBtn setTitle:@"开始监听" forState:UIControlStateNormal];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    _tableView.rowHeight = 44.0f;
    
}

#pragma mark - UIButton Event
- (void)rightBtnCLick:(id)sender
{
    [_textField resignFirstResponder];
    if(_textField.text==nil||_textField.text.length<=0) {
        [MBHUDHelper showWarningWithText:@"请输入端口号"];
        return;
    }
    if(!isRunning)
    {
        int port = [_textField.text intValue];
        
        if (port < 0 || port > 65535)
        {
            _textField.text = @"";
            port = 0;
        }
        
        NSError *error = nil;
        if(![_listenSocket acceptOnPort:port error:&error])
        {
            ITTDPRINT(@"Error starting server: %@",error);
            return;
        }
        
        ITTDPRINT(@"Echo server started on port %hu", [_listenSocket localPort]);
        isRunning = YES;
        
        [_textField setEnabled:NO];
        [_rightBtn setTitle:@"start" forState:UIControlStateNormal];
    }
    else
    {
        // Stop accepting connections
        [_listenSocket disconnect];
        
        // Stop any client connections
        @synchronized(_connectedSockets)
        {
            NSUInteger i;
            for (i = 0; i < [_connectedSockets count]; i++)
            {
                // Call disconnect on the socket,
                // which will invoke the socketDidDisconnect: method,
                // which will remove the socket from the list.
                [[_connectedSockets objectAtIndex:i] disconnect];
            }
        }
        ITTDPRINT(@"Stopped Echo server");
        isRunning = false;
        [_textField setEnabled:YES];
        [_rightBtn setTitle:@"Start" forState:UIControlStateNormal];
    }
}

#pragma mark - Lifecycle Method

-(void)linkRef
{
    self.tableViewRef = _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initDatas];
    [self initViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    
    
    return cell;
}

#pragma mark -  GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    // This method is executed on the socketQueue (not the main thread)
    
    @synchronized(_connectedSockets)
    {
        [_connectedSockets addObject:newSocket];
    }
    
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            ITTDPRINT(@"%@",FORMAT(@"Accepted client %@:%hu", host, port));
        }
    });
    
    NSString *welcomeMsg = @"Welcome to the AsyncSocket Echo Server\r\n";
    NSData *welcomeData = [welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    
    [newSocket writeData:welcomeData withTimeout:-1 tag:WELCOME_MSG];
    
    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    if (tag == ECHO_MSG)
    {
        [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    // This method is executed on the socketQueue (not the main thread)
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            
            NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
            NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
            if (msg)
            {
                ITTDPRINT(@"%@",msg);
            }
            else
            {
                ITTDPRINT(@"%@",@"Error converting received data into UTF-8 String");
            }
            
        }
    });
    
    // Echo message back to client
    [sock writeData:data withTimeout:-1 tag:ECHO_MSG];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    NSLog(@"elapsed:%f",elapsed);
    if (elapsed <= READ_TIMEOUT)
    {
        NSString *warningMsg = @"Are you still there?\r\n";
        NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
        
        [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
        
        return READ_TIMEOUT_EXTENSION;
    }
    
    return 0.0;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock != _listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                
                ITTDPRINT(@"%@",FORMAT(@"Client Disconnected"));
                
            }
        });
        
        @synchronized(_connectedSockets)
        {
            [_connectedSockets removeObject:sock];
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

#import "VoVong.h"
#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
#import <QuartzCore/QuartzCore.h>
//#import "mahoa.h"
#import "Support/RKDropdownAlert.h"

NSString * const __kCheckKeyURLFormat = @"https://severapihax.getbasic.link/Cheack.php?key=%@&&uuid=%@&&hash=%@";
NSString * const __kContactURLFormat = @"https://severapihax.getbasic.link/debcontact.php?hash=%@";

@interface vovongios () <SFSafariViewControllerDelegate>
@property (nonatomic, strong) UIButton *btnConsole;
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, assign) NSInteger countdownSeconds;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, strong) NSString *serverTitle;
@property (nonatomic, strong) UIColor *serverTitleColor;
@end

@implementation vovongios
static vovongios *extraInfo;

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        extraInfo = [vovongios new];
        [[NSNotificationCenter defaultCenter] addObserver:extraInfo
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];

        NSString *savedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedKey"];
        if (savedKey) {
            [extraInfo checkKeyExistence:savedKey];
        } else {
            [extraInfo presentKeyInputAlert];
        }
    });
}

- (void)applicationWillEnterForeground {
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedKey"];
    if (savedKey) {
        [self checkKeyExistence:savedKey];
    } else {
        [self presentKeyInputAlert];
    }
}

// Present alert to input key
- (void)presentKeyInputAlert {
    if (self.alertController.presentingViewController) {
        return;
    }

    NSString *hash = __kHashDefaultValue;
    NSString *urlString = [NSString stringWithFormat:__kContactURLFormat, hash];
    NSURL *contactURL = [NSURL URLWithString:urlString];
    
    if (contactURL) {
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:contactURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"Error fetching server title and color: %@", error.localizedDescription);
                return;
            }

            NSError *jsonError;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                NSLog(@"JSON Error: %@", jsonError.localizedDescription);
                return;
            }

            NSString *title = responseDict[@"nolicaftions"]; 
            NSInteger colorCode = [responseDict[@"colorcode"] integerValue];
            UIColor *titleColor = [self colorFromCode:colorCode];

            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

                self.alertController = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];

                if (titleColor) {
                    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
                    [attributedTitle addAttribute:NSForegroundColorAttributeName value:titleColor range:NSMakeRange(0, attributedTitle.length)];
                    [attributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:24] range:NSMakeRange(0, attributedTitle.length)];
                    [self.alertController setValue:attributedTitle forKey:@"attributedTitle"];
                }

                self.alertController.message = @"Vui lòng nhập key trong vòng 1 phút để tiếp tục sử dụng dịch vụ";

                [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"Nhập Key Ở Đây";
                    textField.secureTextEntry = YES;
                }];

                UIAlertAction *contactAction = [UIAlertAction actionWithTitle:@"Liên Hệ" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSString *hash = __kHashDefaultValue;
                    NSString *urlString = [NSString stringWithFormat:__kContactURLFormat, hash];
                    NSURL *contactURL = [NSURL URLWithString:urlString];
                    
                    if (contactURL) {
                        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:contactURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                            if (error) {
                                NSLog(@"Error: %@", error.localizedDescription);
                                return;
                            }
                            
                            NSError *jsonError;
                            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                            if (jsonError) {
                                NSLog(@"JSON Error: %@", jsonError.localizedDescription);
                                return;
                            }
                            
                            NSString *contactURLString = responseDict[@"contact"];
                            NSURL *contactURL = [NSURL URLWithString:contactURLString];
                            if (contactURL) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:contactURL];
                                    safariViewController.delegate = self;
                                    [rootViewController presentViewController:safariViewController animated:YES completion:nil];
                                });
                            } else {
                                NSLog(@"Invalid contact URL");
                            }
                        }];
                        [task resume];
                    } else {
                        NSLog(@"Invalid URL");
                    }
                }];

                UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Xác Nhận" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self stopCountdownTimer];
                    UITextField *textField = self.alertController.textFields.firstObject;
                    NSString *key = textField.text;
                    [self checkKeyExistence:key];
                }];

                [self.alertController addAction:contactAction];
                [self.alertController addAction:confirmAction];

                [rootViewController presentViewController:self.alertController animated:YES completion:nil];

                self.countdownSeconds = 60;
                self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats:YES];
            });
        }];
        [task resume];
    } else {
        NSLog(@"Invalid URL");
    }
}

- (void)updateCountdown {
    self.countdownSeconds--;
    if (self.countdownSeconds <= 0) {
        [self stopCountdownTimer];
        [self.alertController dismissViewControllerAnimated:YES completion:^{
            exit(0);
        }];
    } else {
        NSInteger minutes = (self.countdownSeconds % (60 * 60)) / 60;
        NSInteger seconds = self.countdownSeconds % 60;
        
        NSString *message = [NSString stringWithFormat:@"Ứng dụng thoát sau %ld phút %ld giây, Nhập key để tiếp tục", (long)minutes, (long)seconds];
        self.alertController.message = message;
    }
}

- (void)stopCountdownTimer {
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
}

- (void)checkKeyExistence:(NSString *)key {
    NSString *uuid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    NSString *hash = __kHashDefaultValue;
    NSString *urlString = [NSString stringWithFormat:__kCheckKeyURLFormat, key, uuid, hash];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self showAlertWithTitle:@"Lỗi" message:@"Không thể kết nối đến server. Vui lòng thử lại sau." shouldExit:NO];
            return;
        }

        NSError *jsonError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

        if (jsonError) {
            [self showAlertWithTitle:@"Lỗi" message:@"Dữ liệu không hợp lệ được trả về từ server" shouldExit:NO];
            return;
        }

        NSString *status = responseDict[@"status"];
        if ([status isEqualToString:@"success"]) {
            NSString *serverTimeString = responseDict[@"time"];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
            NSDate *serverTime = [dateFormatter dateFromString:serverTimeString];

            if (serverTime) {
                NSDate *currentTime = [NSDate date];
                NSTimeInterval timeDifference = [currentTime timeIntervalSinceDate:serverTime];

                if (fabs(timeDifference) > 3) {
                    [self showAlertWithTitle:@"Lỗi" message:@"Thời gian không đồng bộ với server. Vui lòng thử lại" shouldExit:YES];
                    return;
                }

                NSInteger remainingSeconds = [responseDict[@"amount"] integerValue];
                if (remainingSeconds == 0) {
                    NSString *errorMessage = responseDict[@"messenger"] ?: @"Key đã hết hạn! Vui lòng liên hệ với quản trị viên để nhận mã khóa mới!";

                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedKey"];
                    [[NSUserDefaults standardUserDefaults] synchronize];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showAlertWithTitle:errorMessage message:nil shouldExit:YES];
                    });
                } else {
                    NSInteger days = remainingSeconds / (60 * 60 * 24);
                    remainingSeconds %= (60 * 60 * 24);
                    NSInteger hours = remainingSeconds / (60 * 60);
                    remainingSeconds %= (60 * 60);
                    NSInteger minutes = remainingSeconds / 60;
                    remainingSeconds %= 60;

                    NSString *message1 = @"SERVER KEY by Vô Vọng";
                    NSString *message2 = [NSString stringWithFormat:@"Thời hạn sử dụng: %ld ngày, %ld giờ, %ld phút, %ld giây", (long)days, (long)hours, (long)minutes, (long)remainingSeconds];

                    [[NSUserDefaults standardUserDefaults] setObject:key forKey:@"savedKey"];
                    [[NSUserDefaults standardUserDefaults] synchronize];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

                        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"SUSCESS\n\n%@\n\n%@", message1, message2]];

                        [attributedMessage addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, attributedMessage.length)];
                        NSRange xinChaoRange = [attributedMessage.string rangeOfString:@"SUSCESS"];
                        [attributedMessage addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:24] range:xinChaoRange];
                        [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:xinChaoRange];

                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
                        [alertController setValue:attributedMessage forKey:@"attributedMessage"];

                        [rootViewController presentViewController:alertController animated:YES completion:nil];

                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [alertController dismissViewControllerAnimated:YES completion:nil];
                        });
                    });
                }
            } else {
                [self showAlertWithTitle:@"Lỗi" message:@"Thời gian không đồng bộ với server. Vui lòng thử lại" shouldExit:YES];
                return;
            }
        } else {
            NSString *errorMessage = responseDict[@"messenger"];

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedKey"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self showAlertWithTitle:errorMessage message:nil shouldExit:NO]; 

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self presentKeyInputAlert];
            });
        }
    }];
    [task resume];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message shouldExit:(BOOL)shouldExit {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [rootViewController presentViewController:alertController animated:YES completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [alertController dismissViewControllerAnimated:YES completion:^{
                if (shouldExit) {
                    exit(0);
                }
            }];
        });
    });
}

- (UIColor *)colorFromCode:(NSInteger)code {
    switch (code) {
        case 1:
            return [UIColor redColor];
        case 2:
            return [UIColor orangeColor];
        case 3:
            return [UIColor yellowColor];
        case 4:
            return [UIColor greenColor];
        case 5:
            return [UIColor blueColor];
        case 6:
            return [UIColor purpleColor];
        case 7:
            return [UIColor whiteColor];
        default:
            return nil;
    }
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self presentKeyInputAlert];
}

@end
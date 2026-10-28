#import <UIKit/UIKit.h>
#import <spawn.h>
#import <sys/stat.h>
#import <sys/wait.h>
#import <string.h>

extern char **environ;

@interface QFAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

// 用 posix_spawn 执行命令，返回 nil 表示成功，否则返回错误描述
static NSString *RunCmd(NSString *path, NSArray *args) {
    char **argv = calloc(args.count + 1, sizeof(char*));
    for (NSUInteger i = 0; i < args.count; i++) argv[i] = (char*)[args[i] UTF8String];
    argv[args.count] = NULL;
    pid_t pid;
    int rc = posix_spawn(&pid, path.UTF8String, NULL, NULL, argv, environ);
    free(argv);
    if (rc != 0) return [NSString stringWithFormat:@"spawn %@ 失败: %d", path.lastPathComponent, rc];
    int status = 0;
    waitpid(pid, &status, 0);
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) return nil;
    return [NSString stringWithFormat:@"%@ 退出码 %d", path.lastPathComponent, WIFEXITED(status) ? WEXITSTATUS(status) : -1];
}

@implementation QFAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    UILabel *label = [[UILabel alloc] initWithFrame:vc.view.bounds];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    label.text = @"QFUbuntu\n启动中…";
    [vc.view addSubview:label];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *bundle = [[NSBundle mainBundle] bundlePath];
        NSString *tar = [bundle stringByAppendingPathComponent:@"rootfs.tar.gz"];
        NSString *dest = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ubuntu-rootfs"];
        NSString *err = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:tar]) {
            err = @"rootfs.tar.gz 未打包进 App";
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:dest error:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:nil];
            err = RunCmd(@"/usr/bin/tar", @[@"-xzf", tar, @"-C", dest]);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err) { label.text = [@"QFUbuntu\n" stringByAppendingString:err]; return; }
            label.text = @"QFUbuntu 24.04.5 ARM64\nrootfs 就绪，chroot 启动 bash…";
            chroot(dest.UTF8String);
            chdir("/");
            RunCmd(@"/bin/bash", @[@"-l"]);
        });
    });
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([QFAppDelegate class]));
    }
}

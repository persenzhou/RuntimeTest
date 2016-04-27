//
//  ViewController.m
//  runtimeTest
//
//  Created by zhoupushan on 16/4/27.
//  Copyright © 2016年 www.niuduz.com. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

@interface Person : NSObject<NSCoding>
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *age;
@property (copy, nonatomic) NSString *avatar;
@property (copy, nonatomic) NSString *birthday;
@property (strong, nonatomic) Person *mother;
@end

@implementation Person
// ======================Runtime Change Ivar====================
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList([Person class], &count);
        for (NSInteger i = 0; i<count; i++)
        {
            Ivar ivar = ivars[i];
            const char *name = ivar_getName(ivar);
            // 取值
            NSString *key = [NSString stringWithUTF8String:name];
            id value = [aDecoder valueForKey:key];
            //赋值
            [self setValue:value forKey:key];
        }
        free(ivars);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList([Person class], &count);
    for (NSInteger i = 0; i<count; i++)
    {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        NSString *key = [NSString stringWithUTF8String:name];
        // 归档
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
        
    }
    free(ivars);
}
@end


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *exchangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *methodSwizzleLabel;
@property (strong, nonatomic) Person *person;
@end

@implementation ViewController
+ (void)load
{
    
    MethodSwizzle([self class], @selector(methodSwizzle), @selector(myMethodSwizzle));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _person = [Person new];
    _person.name = @"name";
    _nameLabel.text = _person.name;
}

- (void)myMethodSwizzle
{
    // 调回 methodSwizzle
    [self myMethodSwizzle];
    _methodSwizzleLabel.text = [NSString stringWithFormat:@"MethodSwizzle  %d",arc4random_uniform(100)];
}

// ======================Runtime Change Ivar====================
- (IBAction)changeIvar:(UIButton *)sender {
    
    // 枚举
    unsigned int count  = 0;
    Ivar *varList = class_copyIvarList([_person class], &count);
    for (NSInteger i = 0; i < count; i++)
    {
        Ivar var = varList[i];
        const char*varName = ivar_getName(var);
        NSLog(@"%s",varName);
    }
    
    // 获取 Ivar
    Ivar var = class_getInstanceVariable([_person class], "_name");
    // 修改Ivar
    NSArray *names = @[@"Persen",@"Peter",@"Rose"];
    NSString *name = names[arc4random_uniform(3)];
    object_setIvar(_person, var, name);
    _nameLabel.text = _person.name;
    
}

// ======================ExchangeImp====================
- (IBAction)exchangeImp
{
    Method mName = class_getInstanceMethod([_person class], @selector(setName:));
    Method mAge = class_getInstanceMethod([_person class], @selector(setAge:));
    
    // 交换 IMP
    method_exchangeImplementations(mName, mAge);
    
    _person.age = @"age:23";
    
    _exchangeLabel.text = _person.name;
    
}

// ======================MethodSwizzle====================
- (IBAction)methodSwizzle
{
    // 😁😁 do nothing
}

void MethodSwizzle(Class c,SEL origSEL,SEL overrideSEL)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod= class_getInstanceMethod(c, overrideSEL);
    //运行时函数class_addMethod 如果发现方法已经存在，会失败返回，目的是为了使用一个重写的方法替换掉原来的方法
    if(class_addMethod(c, origSEL, method_getImplementation(overrideMethod),method_getTypeEncoding(overrideMethod)))
    {
        //addMethod会让目标类的方法指向新的实现，使用replaceMethod再将新的方法指向原先的实现，这样就完成了交换操作。
        
        //如果添加成功(在父类中重写的方法)，再把目标类中的方法替换为旧有的实现
        class_replaceMethod(c,overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else
    {
        //如果添加失败了，就是第二情况(在目标类重写的方法)。这时可以通过method_exchangeImplementations来完成交换:
        method_exchangeImplementations(origMethod,overrideMethod);
    }
}


@end

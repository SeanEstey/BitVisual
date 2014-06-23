//
//  BitVisualTests.m
//  BitVisualTests
//
//  Created by Sean Estey on 2014-06-22.
//  Copyright (c) 2014 Sean Estey. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface BitVisualTests : XCTestCase

@end

@implementation BitVisualTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

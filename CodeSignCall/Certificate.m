//
//  Certificate.m
//  CodeSign
//
//  Created by yrtd on 15/11/6.
//  Copyright © 2015年 kuaiyong. All rights reserved.
//

#import "Certificate.h"

@implementation Certificate
- (instancetype) initWithContentOfFile:(NSString *)filename password:(NSString *)password{
    self = [super init];
    if (self) {
        _filename = filename;
        _password = password;
        [self parseCertificate];
    }
    return self;
}

- (void) parseCertificate {
    NSData* data = [NSData dataWithContentsOfFile:self.filename];
    NSMutableDictionary* options = [NSMutableDictionary new];
    [options setObject:self.password forKey:(id)kSecImportExportPassphrase];
    CFArrayRef items = NULL;
    OSStatus status = SecPKCS12Import((CFDataRef)data, (CFDictionaryRef)options, &items);
    assert(status == errSecSuccess);
    CFDictionaryRef result = CFArrayGetValueAtIndex(items, 0);
    self.label = (NSString*) CFDictionaryGetValue(result, kSecImportItemLabel);
    
    CFArrayRef arrayRef = CFDictionaryGetValue(result, kSecImportItemCertChain);
    SecCertificateRef certificateRef = (SecCertificateRef) CFArrayGetValueAtIndex(arrayRef, 0);;
    CFStringRef summaryRef = SecCertificateCopySubjectSummary(certificateRef);
    CFErrorRef error;
    const void *keys[] = { kSecOIDX509V1SubjectName, kSecOIDX509V1IssuerName };
    CFArrayRef keySelection = CFArrayCreate(NULL, keys , sizeof(keys)/sizeof(keys[0]), &kCFTypeArrayCallBacks);
    
    CFDictionaryRef vals = SecCertificateCopyValues(certificateRef, keySelection,&error);
    NSMutableArray* summary = [NSMutableArray new];
    
    for(int i = 0; i < sizeof(keys)/sizeof(keys[0]); i++) {
        CFDictionaryRef dict = CFDictionaryGetValue(vals, keys[i]);
        [summary addObject:(__bridge NSDictionary*) dict];
    }
    _summary = summary;
    CFRelease(vals);
    CFRelease(summaryRef);
}
@end

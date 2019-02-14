#import "MOUser.h"

@implementation MOUser

// Insert code here to add functionality to your managed object subclass
- (NSString *)description {    
    return [NSString stringWithFormat:@"<%@: base64Handle=%@, firstname=%@, lastname=%@, email=%@>",
            [self class], self.base64userHandle, self.firstname, self.lastname, self.email];
}

- (NSString *)fullName {
    NSString *fullName;
    if (self) {
        if (self.firstname) {
            fullName = self.firstname;
            if (self.lastname) {
                fullName = [[fullName stringByAppendingString:@" "] stringByAppendingString:self.lastname];
            }
        } else {
            if (self.lastname) {
                fullName = self.lastname;
            }
        }
    }
    
    if(![[fullName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        fullName = nil;
    }
    
    return fullName ?: self.email;
}

- (NSString *)firstName {
    NSString *firstname;
    if (self) {
        if (self.firstname) {
            firstname = self.firstname;
        }
    }
    
    return firstname;
}

@end

/*
  Stockfish, a chess program for iOS.
  Copyright (C) 2004-2013 Tord Romstad, Marco Costalba, Joona Kiiski.

  Stockfish is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Stockfish is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "ECO.h"
//#import "Game.h"
//#import "PGN.h"

@interface Opening : NSObject {
   uint64_t key;
   NSString *ecoCode, *opening, *variation;
}

@property (readonly, atomic) uint64_t key;
@property (readonly, atomic) NSString *ecoCode;
@property (readonly, atomic) NSString *opening;
@property (readonly, atomic) NSString *variation;

- (id)initWithString:(NSString *)string;

@end // @interface Opening

@implementation Opening

@synthesize key, ecoCode, opening, variation;

- (id)initWithString:(NSString *)string {
   if (self = [super init]) {
      NSScanner *scanner = [NSScanner scannerWithString: string];
      [scanner scanHexLongLong: &key];

      [scanner scanUpToString: @"\"" intoString: NULL];
      [scanner scanString: @"\"" intoString: NULL];
      [scanner scanUpToString: @"\"" intoString: &ecoCode];
      [ecoCode retain];
      [scanner scanString: @"\"" intoString: NULL];
      
      [scanner scanUpToString: @"\"" intoString: NULL];
      [scanner scanString: @"\"" intoString: NULL];
      [scanner scanUpToString: @"\"" intoString: &opening];
      [opening retain];
      [scanner scanString: @"\"" intoString: NULL];
      
      [scanner scanUpToString: @"\"" intoString: NULL];
      [scanner scanString: @"\"" intoString: NULL];
      [scanner scanUpToString: @"\"" intoString: &variation];
      [variation retain];
      [scanner scanString: @"\"" intoString: NULL];
   }
   return self;
}

- (void)dealloc {
   [ecoCode release];
   [opening release];
   [variation release];
   [super dealloc];
}  

@end // @implementation Opening


static NSInteger compareOpenings(Opening *o1, Opening *o2, void *context) {
   if ([o1 key] < [o2 key])
      return NSOrderedAscending;
   else if ([o1 key] > [o2 key])
      return NSOrderedDescending;
   else
      return NSOrderedSame;
}
   

@implementation ECO


+ (ECO *)sharedInstance {
   static ECO *e = nil;
   if (e == nil)
      e = [[ECO alloc] init];
   return e;
}


- (id)init {
   if (self = [super init]) {
      openings = [[NSMutableArray alloc] init];

      NSString *path = [[NSBundle bundleForClass: [self class]]
                          pathForResource: @"eco"
                                   ofType: @"txt"];
      NSString *contents =
         [NSString stringWithContentsOfFile: path
                                   encoding: NSASCIIStringEncoding
                                      error: nil];
      NSArray *lines =
         [contents componentsSeparatedByCharactersInSet:
                      [NSCharacterSet characterSetWithCharactersInString: @"\n"]];
      Opening *o;
      for (NSString *line in lines) {
         o = [[Opening alloc] initWithString: line];
         [openings addObject: o];
         [o release];
      }
       //NSLog(@"ECO STARTED");
   }
   return self;
}


- (NSString *)openingDescriptionForKey:(uint64_t)key {
   int min = 0, max = (int)[openings count] - 1, mid;
   Opening *o;

   while (max >= min) {
      mid = (max + min) / 2;
      o = [openings objectAtIndex: mid];
      if ([o key] < key)
         min = mid + 1;
      else if ([o key] > key)
         max = mid - 1;
      else if ([[o variation] isEqualToString: @"(null)"]) {
         return [NSString stringWithFormat: @"%@ %@",
                          [o ecoCode], [o opening]];
      }
      else {
         return [NSString stringWithFormat: @"%@ %@, %@",
                          [o ecoCode], [o opening], [o variation]];
      }
   }
   return nil;
}

- (NSArray *)openingForKey:(uint64_t)key {
    NSMutableArray *opArray = [[NSMutableArray alloc] init];
    int min = 0, max = (int)[openings count] - 1, mid;
    Opening *o;
    while (max >= min) {
        mid = (max + min) / 2;
        o = [openings objectAtIndex: mid];
        if ([o key] < key)
            min = mid + 1;
        else if ([o key] > key)
            max = mid - 1;
        else if ([[o variation] isEqualToString: @"(null)"]) {
            [opArray addObject:[o ecoCode]];
            [opArray addObject:[o opening]];
            return opArray;
        }
        else {
            [opArray addObject:[o ecoCode]];
            [opArray addObject:[o opening]];
            [opArray addObject:[o variation]];
            return opArray;
        }
    }
    return nil;
}

- (NSMutableArray *) getAllValues {
    NSMutableArray *all = [[NSMutableArray alloc] init];
    for (Opening *p in openings) {
        NSMutableString *riga = [[NSMutableString alloc] init];
        if ([p ecoCode]) {
            [riga appendString:[p ecoCode]];
        }
        if ([p opening] != NULL) {
            [riga appendString:@" "];
            [riga appendString:[p opening]];
        }
        if ([p variation] != NULL) {
            [riga appendString:@": "];
            [riga appendString:[p variation]];
        }
        [all addObject:riga];
    }
    return all;
}


- (void)dealloc {
   [openings release];
   [super dealloc];
}

@end

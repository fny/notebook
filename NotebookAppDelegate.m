/*
 * Copyright 2010 Tim Horton. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY TIM HORTON "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL TIM HORTON OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

#import "NotebookAppDelegate.h"

#import "NBCell.h"

@implementation NotebookAppDelegate

@synthesize window;
@synthesize notebookView;
@synthesize notebookController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NBCell * cell;
    
    cell = [[NBCell alloc] init];
    cell.content = @"import random";
    [notebookController notebookView:notebookView addCell:cell afterCellView:nil];
    
    cell = [[NBCell alloc] init];
    cell.content = @"def doSomethingRandom(max=5):\n    return random.uniform(0, max)";
    [notebookController notebookView:notebookView addCell:cell afterCellView:nil];
    
    cell = [[NBCell alloc] init];
    cell.content = @"print doSomethingRandom()";
    [notebookController notebookView:notebookView addCell:cell afterCellView:nil];
    
    cell = [[NBCell alloc] init];
    cell.content = @"for x in range(100000):\n    print x";
    [notebookController notebookView:notebookView addCell:cell afterCellView:nil];
}

@end

/*
 * Copyright 2011 Tim Horton. All rights reserved.
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

#import <Carbon/Carbon.h>

#import "NBNotebookView.h"

#import "NBSourceCellView.h"
#import "NBCommentCellView.h"
#import <NBSettings/NBSettings.h>
#import "NBCellView.h"

@interface NBNotebookView ()

- (void)viewDidResize:(NSNotification *)aNotification;

@end


@implementation NBNotebookView

@synthesize notebook;
@synthesize selectedCellViews;
@synthesize cellViews;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if(self)
    {
        cellViews = [NSMapTable mapTableWithStrongToStrongObjects];
        selectedCellViews = [[NSMutableArray alloc] init];
        addCellTrackingAreas = [[NSMutableArray alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self];

        CFRetain([[NSNotificationCenter defaultCenter] addObserverForName:NBThemeChangedNotification
                                                                   object:nil
                                                                    queue:nil
                                                               usingBlock:^(NSNotification * arg1)
        {
            [self relayoutViews];
            [self setNeedsDisplay:YES];
        }]);
    }

    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (id)undoManager
{
    return [super undoManager];
}

- (void)setNotebook:(NBNotebook *)inNotebook
{
    NSUInteger index = 0;

    notebook = inNotebook;
    notebook.delegate = self;

    // Create NBCellViews for any NBCells that were added before this view was created

    for(NBCell * cell in notebook.cells)
    {
        [self cellAdded:cell atIndex:index++];
    }
}

- (void)viewDidResize:(NSNotification *)aNotification
{
    [self relayoutViews];
}

- (void)cellAdded:(NBCell *)cell atIndex:(NSUInteger)index
{
    NBCellView * cellView;

    switch(cell.type)
    {
        case NBCellSnippet:
            cellView = [[NBSourceCellView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 12)];
            break;
        case NBCellComment:
            cellView = [[NBCommentCellView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 12)];
            break;
        default:
            NSLog(@"Unknown cell type %d", cell.type);
            break;
    }

    cellView.cell = cell;
    cellView.delegate = self;

    [cellViews setObject:cellView forKey:cell];

    [self addSubview:cellView];
    [cellView setFrameOrigin:NSMakePoint(0, [self yForView:cellView])];

    [[cellView window] makeFirstResponder:cellView];

    [self relayoutViews];
}

- (void)cellRemoved:(NBCell *)cell
{
    [[cellViews objectForKey:cell] removeFromSuperview];
    [cellViews removeObjectForKey:cell];

    [self relayoutViews];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // TODO: need to be able to add different kinds of cells

    if(appendingCellView)
    {
        NBCell * newCell = [[NBCell alloc] init];
        newCell.type = NBCellSnippet;

        if((NSNull *)appendingCellView == [NSNull null])
        {
            [notebook addCell:newCell atIndex:0];
        }
        else
        {
            [notebook addCell:newCell afterCell:appendingCellView.cell];
        }
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSDictionary * userData = (NSDictionary *)[theEvent userData];

    if([[userData objectForKey:@"reason"] isEqualToString:@"addCell"])
    {
        appendingCellView = (NBCellView *)[userData objectForKey:@"cellView"];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    NSDictionary * userData = (NSDictionary *)[theEvent userData];

    if([[userData objectForKey:@"reason"] isEqualToString:@"addCell"])
    {
        appendingCellView = nil;
    }
}

- (float)yForView:(NBCellView *)cellView
{
    NBSettingsController * settings = [NBSettingsController sharedInstance];
    float cellSpacing = [(NSNumber *)[settings settingWithKey:@"cellSpacing"] floatValue];
    float y = cellSpacing;

    for(NBCell * cell in notebook.cells)
    {
        NBCellView * otherView = [cellViews objectForKey:cell];

        if(otherView == cellView)
            return y;

        y += [otherView requestedHeight] + cellSpacing;
    }

    return 0;
}

- (void)relayoutViews
{
    NBSettingsController * settings = [NBSettingsController sharedInstance];

    float cellSpacing = [(NSNumber *)[settings settingWithKey:@"cellSpacing"] floatValue];

    NSTrackingArea * trackingArea;
    NSRect trackingRect;

    NSSize totalSize = NSZeroSize;
    totalSize.height = cellSpacing; // TODO: use yForView for these
    totalSize.width = self.frame.size.width;

    for(NSTrackingArea * trackingArea in addCellTrackingAreas)
    {
        [self removeTrackingArea:trackingArea];
    }

    [addCellTrackingAreas removeAllObjects];

    trackingRect = NSMakeRect(0, totalSize.height - cellSpacing, totalSize.width, cellSpacing);
    trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
                                                options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
                                                  owner:self
                                               userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNull null],@"cellView",@"addCell",@"reason",nil]];

    [self addTrackingArea:trackingArea];
    [addCellTrackingAreas addObject:trackingArea];

    for(NBCell * cell in notebook.cells)
    {
        NBCellView * cellView = [cellViews objectForKey:cell];
        float requestedHeight = [cellView requestedHeight];

        [cellView setFrame:NSMakeRect(0, totalSize.height, totalSize.width, requestedHeight)];

        totalSize.height += requestedHeight + cellSpacing;

        trackingRect = NSMakeRect(0, totalSize.height - cellSpacing, totalSize.width, cellSpacing);
        trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
                                                    options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
                                                      owner:self
                                                   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cellView,@"cellView",@"addCell",@"reason",nil]];

        [self addTrackingArea:trackingArea];
        [addCellTrackingAreas addObject:trackingArea];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self];
    [self setFrameSize:totalSize];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidResize:) name:NSViewFrameDidChangeNotification object:self];
}

- (void)cellViewResized:(NBCellView *)cellView
{
    [self relayoutViews];
}

- (void)cellViewTookFocus:(NBCellView *)cellView
{
    for(NBCellView * defocusView in [cellViews objectEnumerator])
    {
        if(defocusView == cellView)
            continue;

        [defocusView clearSelection];
    }

    for(NBCellView * deselectView in [selectedCellViews copy])
    {
        deselectView.selected = NO;
    }

    [selectedCellViews removeAllObjects];
}

- (void)selectAll
{
    [self deselectAll];

    for(NBCellView * cellView in [cellViews objectEnumerator])
    {
        [self selectedCell:cellView];
    }
}

- (void)deselectAll
{
    [[self window] makeFirstResponder:self];

    for(NBCellView * defocusView in [cellViews objectEnumerator])
    {
        [defocusView clearSelection];
    }

    for(NBCellView * deselectView in [selectedCellViews copy])
    {
        deselectView.selected = NO;
    }

    [selectedCellViews removeAllObjects];
}

- (void)selectedCell:(NBCellView *)cellView
{
    if(cellView)
    {
        cellView.selected = YES;
        [selectedCellViews addObject:cellView];
    }
}

- (void)deselectedCell:(NBCellView *)cellView
{
    if(cellView)
    {
        cellView.selected = NO;
        [selectedCellViews removeObject:cellView];
    }
}

@end

//
//  NBPersonViewController.m
//  NBClientExample
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBPersonViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "NBPersonViewDataSource.h"

typedef NS_ENUM(NSUInteger, NBTextViewGroupIndex) {
    NBTextViewGroupIndexView = 0,
    NBTextViewGroupIndexHeightConstraint,
};

static NSDictionary *DefaultNibNames;

static NSString *PersonKeyPath;
static void *observationContext = &observationContext;

static NSDictionary *DataToFieldKeyPathsMap;

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBPersonViewController ()

<UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong, readwrite) NSMutableDictionary *nibNames;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *scrollViewBottomConstraint;
@property (nonatomic, weak) IBOutlet UIImageView *profileImageView;

@property (nonatomic, weak) IBOutlet UITextView *nameField;

@property (nonatomic, weak) IBOutlet UILabel *emailLabel;
@property (nonatomic, weak) IBOutlet UITextField *emailField;

@property (nonatomic, weak) IBOutlet UILabel *phoneLabel;
@property (nonatomic, weak) IBOutlet UITextField *phoneField;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITextField *titleField;

@property (nonatomic, weak) IBOutlet UILabel *tagsLabel;
@property (nonatomic, weak) IBOutlet UITextView *tagsField;

@property (nonatomic, strong) NSArray *fields;

@property (nonatomic, weak) id keyboardDidShowObserver;
@property (nonatomic, weak) id keyboardWillHideObserver;
@property (nonatomic) UIEdgeInsets originalContentInset;

@property (nonatomic, strong) UIView *activeField;

@property (nonatomic, readonly, getter = isPresentedAsModal) BOOL presentedAsModal;
@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;

@property (nonatomic, strong) UIBarButtonItem *deleteButtonItem;
@property (nonatomic, strong) UIAlertView *deleteConfirmationView;

- (void)reloadData;
- (void)saveData;
- (void)deleteData;

- (void)setUpAppearance;

- (void)setUpCreating;

- (void)setUpEditing;
- (void)tearDownEditing;
- (void)setField:(id)field enabled:(BOOL)enabled;
- (IBAction)toggleEditing:(id)sender;

- (void)changeToNextField;

- (void)setUpDeleting;
- (void)tearDownDeleting;

- (IBAction)presentErrorView:(id)sender;
- (IBAction)dismiss:(id)sender;

@end

@implementation NBPersonViewController

@synthesize dataSource = _dataSource;
@synthesize busy = _busy;
@synthesize busyIndicator = _busyIndicator;
@synthesize cancelButtonItem = _cancelButtonItem;

- (instancetype)initWithNibNames:(NSDictionary *)nibNamesOrNil
                          bundle:(NSBundle *)nibBundleOrNil
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DefaultNibNames = @{ NBNibNameViewKey: NSStringFromClass([self class]) };
        PersonKeyPath = NSStringFromSelector(@selector(person));
        DataToFieldKeyPathsMap = @{ @"full_name": @"nameField.text",
                                    @"email": @"emailField.text",
                                    @"phone": @"phoneField.text",
                                    @"occupation": @"titleField.text",
                                    @"tags_text": @"tagsField.text" };
    });
    self = [self initWithNibName:self.nibNames[NBNibNameViewKey] bundle:nibBundleOrNil];
    self.mode = NBPersonViewControllerModeViewAndEdit;
    // Boilerplate.
    self.nibNames = DefaultNibNames.mutableCopy;
    [self.nibNames addEntriesFromDictionary:nibNamesOrNil];
    // END: Boilerplate.
    return self;
}

- (void)dealloc
{
    self.dataSource = nil;
    [self tearDownEditing];
    [self tearDownDeleting];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self dismiss:self];
    [self.dataSource cleanUp:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self reloadData];
    [self setUpAppearance];
    [self setUpEditing];
    if (self.mode == NBPersonViewControllerModeCreate) {
        [self setUpCreating];
    } else {
        [self setUpDeleting];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    // Update UI.
    for (id field in self.fields) {
        [self setField:field enabled:editing];
    }
    if (editing) {
        [self changeToNextField];
        if (self.navigationItem.leftBarButtonItem != self.cancelButtonItem) {
            [self.navigationItem setLeftBarButtonItem:self.cancelButtonItem animated:YES];
        }
    } else {
        self.activeField = nil;
        if (self.navigationController.modalPresentationStyle == UIModalPresentationFormSheet) {
            [self.navigationItem setLeftBarButtonItem:self.closeButtonItem animated:YES];
        } else {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
}

#pragma mark - NBViewController

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

- (void)setDataSource:(id<NBViewDataSource>)dataSource
{
    // Teardown.
    if (self.dataSource) {
        [(id)self.dataSource removeObserver:self forKeyPath:PersonKeyPath context:&observationContext];
        [(id)self.dataSource removeObserver:self forKeyPath:NBViewDataSourceErrorKeyPath context:&observationContext];
    }
    // Set.
    _dataSource = dataSource;
    // Set up.
    if (self.dataSource) {
        NSAssert([self.dataSource isKindOfClass:[NBPersonViewDataSource class]], @"Data source must be of certain type.");
        [(id)self.dataSource addObserver:self forKeyPath:PersonKeyPath options:0 context:&observationContext];
        [(id)self.dataSource addObserver:self forKeyPath:NBViewDataSourceErrorKeyPath options:0 context:&observationContext];
        if (self.isViewLoaded) {
            [self reloadData];
        }
    }
}

#pragma mark Busy & Cancel

- (void)setBusy:(BOOL)busy
{
    // Guard.
    if (busy == _busy) { return; }
    // Set.
    _busy = busy;
    // Did.
    if (busy) {
        self.navigationItem.titleView = self.busyIndicator;
        [self.busyIndicator startAnimating];
    } else {
        self.navigationItem.titleView = nil;
        [self.busyIndicator stopAnimating];
    }
}

- (UIActivityIndicatorView *)busyIndicator
{
    if (_busyIndicator) {
        return _busyIndicator;
    }
    self.busyIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    return _busyIndicator;
}

- (UIBarButtonItem *)cancelButtonItem
{
    if (_cancelButtonItem) {
        return _cancelButtonItem;
    }
    self.cancelButtonItem = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                             target:self action:@selector(cancelPendingAction:)];
    return _cancelButtonItem;
}

- (IBAction)cancelPendingAction:(id)sender
{
    [(id)self.dataSource cancelSave];
    if (self.mode == NBPersonViewControllerModeCreate) {
        [self dismiss:sender];
    } else {
        // Keep editing.
        [self toggleEditing:sender];
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &observationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    NBPersonViewDataSource *dataSource = self.dataSource;
    // Update when our data source changes.
    if ([keyPath isEqual:PersonKeyPath]) {
        if (self.isBusy) { // If we were busy refreshing data, now we're not.
            self.busy = NO;
        }
        if (self.mode == NBPersonViewControllerModeCreate) {
            // Just exit on create success.
            [self dismiss:self];
        } else if (!dataSource.person) {
            // Also exit on delete success.
            [self dismiss:self];
        } else {
            // Updated.
            if (self.isViewLoaded) {
                [self reloadData];
            }
        }
    } else if ([keyPath isEqual:NBViewDataSourceErrorKeyPath] && self.dataSource.error) {
        if (self.isBusy) { // If we were busy refreshing data, now we're not.
            self.busy = NO;
        }
        [self presentErrorView:self];
        if (self.mode == NBPersonViewControllerModeCreate) {
            // Keep editing.
            [self toggleEditing:self];
        } else {
            // Reset changes if we're updating.
            if (self.isViewLoaded) {
                [self reloadData];
            }
        }
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    if (textField.returnKeyType == UIReturnKeyNext) {
        [self changeToNextField];
        shouldReturn = NO;
    }
    return shouldReturn;
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.activeField = textView;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange = YES;
    if (textView.returnKeyType == UIReturnKeyNext && [text isEqualToString:@"\n"]) {
        [self changeToNextField];
        shouldChange = NO;
    }
    return shouldChange;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.deleteConfirmationView && buttonIndex != alertView.cancelButtonIndex) {
        [self confirmDeleting:alertView];
    }
}

#pragma mark - Private

- (NSArray *)fields
{
    if (_fields) {
        return _fields;
    }
    self.fields = @[ self.nameField,
                     self.emailField,
                     self.phoneField,
                     self.titleField,
                     self.tagsField ];
    return _fields;
}

- (BOOL)isPresentedAsModal
{
    return (self.presentingViewController.presentedViewController == self ||
            self.navigationController.presentingViewController.presentedViewController == self.navigationController ||
            [self.tabBarController.presentingViewController isKindOfClass:[UITabBarController class]]);
}

- (UIBarButtonItem *)closeButtonItem
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                         target:self action:@selector(dismiss:)];
}

#pragma mark Data

- (void)reloadData
{
    NBPersonViewDataSource *dataSource = self.dataSource;
    NSDictionary *data = dataSource.person;
    self.title = data[@"first_name"];
    // Profile image, without blocking the UI.
    NSString *urlString = data[@"profile_image_url_ssl"];
    if (!dataSource.profileImage && urlString.length) {
        UIImageView *imageView = self.profileImageView;
        imageView.alpha = 0.0f;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
            if (!imageData) {
                NBLogWarning(@"Invalid profile image URL %@", urlString);
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                dataSource.profileImage = [UIImage imageWithData:imageData];
                imageView.image = dataSource.profileImage;
                [UIView animateWithDuration:0.2f animations:^{ imageView.alpha = 1.0f; }];
            });
        });
    } else {
        self.profileImageView.image = dataSource.profileImage;
    }
    // Dynamically update fields.
    [DataToFieldKeyPathsMap enumerateKeysAndObjectsUsingBlock:^(NSString *dataKeyPath, NSString *fieldKeyPath, BOOL *stop) {
        [self setValue:[data valueForKeyPath:dataKeyPath] forKeyPath:fieldKeyPath];
    }];
    // Invalidate any views.
    self.deleteConfirmationView = nil;
}

- (void)saveData
{
    NBPersonViewDataSource *dataSource = self.dataSource;
    NSMutableDictionary *changes = dataSource.changes;
    // Dynamically update changes.
    [DataToFieldKeyPathsMap enumerateKeysAndObjectsUsingBlock:^(NSString *dataKeyPath, NSString *fieldKeyPath, BOOL *stop) {
        [changes setValue:[self valueForKeyPath:fieldKeyPath] forKeyPath:dataKeyPath];
    }];
    BOOL willSave = [(id)self.dataSource save];
    self.busy = willSave;
}

- (void)deleteData
{
    BOOL willDelete = [(id)self.dataSource nb_delete];
    self.busy = willDelete;
}

#pragma mark Appearance

- (void)setUpAppearance
{
    self.profileImageView.layer.cornerRadius = self.subviewCornerRadius.floatValue * 2.0f; // A little rounder to stand out.
    if (self.mode == NBPersonViewControllerModeCreate) {
        self.profileImageView.backgroundColor = self.editingBackgroundColor;
    }
    for (UIView *field in self.fields) {
        field.layer.cornerRadius = self.subviewCornerRadius.floatValue;
        if ([field isKindOfClass:[UITextView class]]) {
            CGSize insetSize = self.textFieldInsetSize;
            // WARNING: The insets values are tweaked to align visually and are probably not very flexible.
            [(id)field setTextContainerInset:UIEdgeInsetsMake(/* top: */ insetSize.height,
                                                              /* left: */ insetSize.width / 2.0f,
                                                              /* bottom: */ insetSize.height,
                                                              /* right: */ insetSize.width / 2.0f)];
        }
    }
    if (self.isPresentedAsModal) {
        if (self.navigationController.modalPresentationStyle == UIModalPresentationFormSheet) {
            self.navigationItem.leftBarButtonItem = self.closeButtonItem;
        } else {
            self.navigationItem.leftBarButtonItem = self.cancelButtonItem;
        }
    }
}

#pragma mark Creating

- (void)setUpCreating
{
    self.title = NSLocalizedString(@"person.navigation-title.create", nil);
    NSAssert(self.keyboardDidShowObserver, @"Editing must be set up.");
    [self toggleEditing:self];
}

#pragma mark Editing

- (void)setUpEditing
{
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editButtonItem.target = self;
    self.editButtonItem.action = @selector(toggleEditing:);
    self.editing = NO;
    // Integrate with keyboard.
    __weak __typeof(self)weakSelf = self;
    self.keyboardDidShowObserver =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIKeyboardDidShowNotification object:nil queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         if (self.navigationController.modalPresentationStyle == UIModalPresentationFormSheet) {
             // TODO: Handle size as form-sheet modal.
             return;
         }
         CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
         keyboardFrame = [weakSelf.scrollView convertRect:keyboardFrame fromView:nil];
         weakSelf.scrollViewBottomConstraint.constant = keyboardFrame.size.height;
         [weakSelf.view setNeedsUpdateConstraints];
         [UIView
          animateWithDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0f
          options:[note.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]|UIViewAnimationOptionBeginFromCurrentState
          animations:^{ [weakSelf.view layoutIfNeeded]; } completion:nil];
     }];
    self.keyboardWillHideObserver =
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification *note) {
         if (self.navigationController.modalPresentationStyle == UIModalPresentationFormSheet) {
             // TODO: Handle size as form-sheet modal.
             return;
         }
         weakSelf.scrollViewBottomConstraint.constant = 0.0f;
         [weakSelf.view setNeedsUpdateConstraints];
         [UIView
          animateWithDuration:[note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] delay:0.0f
          options:[note.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]|UIViewAnimationOptionBeginFromCurrentState
          animations:^{ [weakSelf.view layoutIfNeeded]; } completion:nil];
     }];
}
- (void)tearDownEditing
{
    self.editing = NO;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self.keyboardDidShowObserver];
    [center removeObserver:self.keyboardWillHideObserver];
}

- (void)setField:(id)field enabled:(BOOL)enabled
{
    if ([field isKindOfClass:[UITextField class]]) {
        [field setEnabled:enabled];
    } else if ([field isKindOfClass:[UITextView class]]) {
        [field setEditable:enabled];
        [field setSelectable:enabled];
    }
    [UIView
     animateWithDuration:self.editingAnimationDuration.floatValue delay:0.0f
     options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
     animations:^{
         [field setBackgroundColor:(enabled ? self.editingBackgroundColor : [UIColor clearColor])];
     } completion:nil];
}

- (IBAction)toggleEditing:(id)sender
{
    BOOL shouldSave = self.isEditing && sender != self.cancelButtonItem;
    if (shouldSave) {
        [self saveData];
    }
    BOOL editing = !self.isEditing;
    // More code here to guard against setting `editing` as needed.
    [self setEditing:editing animated:YES];
}

- (void)changeToNextField
{
    NSAssert(self.isEditing, @"Must be in editing state.");
    NSUInteger index = !self.activeField ? 0 : [self.fields indexOfObject:self.activeField] + 1;
    if (index < self.fields.count) {
        self.activeField = self.fields[index];
        [self.activeField becomeFirstResponder]; // Animates.
    } else {
        [self.activeField resignFirstResponder]; // Animates.
        [self toggleEditing:self];
    }
}

#pragma mark Deleting

- (void)setUpDeleting
{
    [self.navigationItem setRightBarButtonItems:
     [self.navigationItem.rightBarButtonItems arrayByAddingObject:self.deleteButtonItem]];
}
- (void)tearDownDeleting
{
    [self.deleteConfirmationView dismissWithClickedButtonIndex:NSNotFound animated:NO];
}

- (UIBarButtonItem *)deleteButtonItem
{
    if (_deleteButtonItem) {
        return _deleteButtonItem;
    }
    self.deleteButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                          target:self action:@selector(confirmDeleting:)];
    return _deleteButtonItem;
}

- (UIAlertView *)deleteConfirmationView
{
    if (_deleteConfirmationView) {
        return _deleteConfirmationView;
    }
    NBPersonViewDataSource *dataSource = self.dataSource;
    self.deleteConfirmationView = [[UIAlertView alloc]
                                   initWithTitle:NSLocalizedString(@"person.confirm-delete.title", nil)
                                   message:[NSString localizedStringWithFormat:
                                            NSLocalizedString(@"person.confirm-delete.message.format", nil),
                                            dataSource.person[@"full_name"]]
                                   delegate:self
                                   cancelButtonTitle:NSLocalizedString(@"label.cancel", nil)
                                   otherButtonTitles:NSLocalizedString(@"label.confirm", nil), nil];
    return _deleteConfirmationView;
}

- (IBAction)confirmDeleting:(id)sender
{
    if (sender == self.deleteButtonItem) {
        // Start.
        [self.deleteConfirmationView show];
    } else if (sender == self.deleteConfirmationView) {
        // Continue.
        [self deleteData];
    }
}

#pragma mark Helpers

- (IBAction)presentErrorView:(id)sender
{
    NSDictionary *error = self.dataSource.error.userInfo;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error[NBUIErrorTitleKey]
                                                        message:error[NBUIErrorMessageKey]
                                                       delegate:self cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"label.ok", nil), nil];
    [alertView show];
}

- (IBAction)dismiss:(id)sender
{
    if (self.isPresentedAsModal) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end

#pragma mark - Minor Subclasses

@interface NBTextField ()

- (CGRect)rectWithInsetSize:(CGSize)insetSize rect:(CGRect)rect;

@end

@implementation NBTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    CGRect rect = [super textRectForBounds:bounds];
    if ([self.delegate respondsToSelector:@selector(textFieldInsetSize)]) {
        rect = [self rectWithInsetSize:[(id)self.delegate textFieldInsetSize] rect:rect];
    }
    return rect;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];
    if ([self.delegate respondsToSelector:@selector(textFieldInsetSize)]) {
        rect = [self rectWithInsetSize:[(id)self.delegate textFieldInsetSize] rect:rect];
    }
    return rect;
}

- (CGRect)rectWithInsetSize:(CGSize)insetSize rect:(CGRect)rect
{
    return UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(/* top: */ insetSize.height,
                                                        /* left: */ insetSize.width,
                                                        /* bottom: */ insetSize.height,
                                                        /* right: */ 0.0f));
}
@end
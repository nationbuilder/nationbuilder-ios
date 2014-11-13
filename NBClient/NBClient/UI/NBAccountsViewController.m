//
//  NBAccountsViewController.m
//  NBClient
//
//  Copyright (c) 2014 NationBuilder. All rights reserved.
//

#import "NBAccountsViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "FoundationAdditions.h"
#import "NBAccountButton.h"
#import "UIKitAdditions.h"

static NSString *IsSignedInKeyPath;
static NSString *SelectedAccountKeyPath;
static void *observationContext = &observationContext;

#if DEBUG
static NBLogLevel LogLevel = NBLogLevelDebug;
#else
static NBLogLevel LogLevel = NBLogLevelWarning;
#endif

@interface NBAccountsViewController () <UIScrollViewDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak, readwrite) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *nationLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIView *accountView;

@property (nonatomic, weak, readwrite) IBOutlet UIButton *signOutButton;
@property (nonatomic, weak, readwrite) IBOutlet UIButton *addAccountButton;

@property (nonatomic, weak, readwrite) IBOutlet UIPickerView *accountsPicker;

@property (nonatomic, weak, readwrite) IBOutlet UIImageView *logoImageView;

// For account view hiding.
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *accountViewHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *accountViewBottomMargin;
@property (nonatomic) CGFloat originalAccountViewHeight;
@property (nonatomic) CGFloat originalAccountViewBottomMargin;

// For sign-out button hiding.
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *signOutButtonHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *signOutButtonTopMargin;
@property (nonatomic) CGFloat originalSignOutButtonHeight;
@property (nonatomic) CGFloat originalSignOutButtonTopMargin;

// For account picker hiding.
@property (nonatomic, weak) IBOutlet UIView *accountsPickerContainer;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *accountsPickerHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *accountsPickerBottomMargin;
@property (nonatomic) CGFloat originalAccountsPickerHeight;
@property (nonatomic) CGFloat originalAccountsPickerBottomMargin;

@property (nonatomic, strong) UIBarButtonItem *closeButtonItem;
@property (nonatomic, strong) UIButton *closeIconButton;

@property (nonatomic, strong) UIAlertView *nationSlugPromptView;
@property (nonatomic, strong) UIAlertView *nationSlugErrorView;

@property (nonatomic, strong) UIPopoverController *containingPopoverController;
@property (nonatomic, weak) UIViewController *customPresentingViewController;

@property (nonatomic, readonly) NSUInteger selectedIndex;
@property (nonatomic, getter = isSelectingAccount) BOOL selectingAccount;

- (IBAction)dismiss:(id)sender;

- (IBAction)signIn:(id)sender;
- (IBAction)signOut:(id)sender;

- (void)didSignOutOfLastAccount;

- (void)updateVisibilityForSubview:(UIView *)subview
                           visible:(BOOL)visible
                          animated:(BOOL)animated
             withCompletionHandler:(void (^)(void))completionHandler;

- (void)setUpAccountView;
- (void)toggleAccountViewVisibility:(BOOL)visible
                           animated:(BOOL)animated
              withCompletionHandler:(void (^)(void))completionHandler;
- (void)updateAccountViewAnimated:(BOOL)animated
            withCompletionHandler:(void (^)(void))completionHandler;

- (void)setUpActionButtons;
- (void)toggleSignOutButtonVisibility:(BOOL)visible
                             animated:(BOOL)animated
                withCompletionHandler:(void (^)(void))completionHandler;
- (void)updateActionButtonsAnimated:(BOOL)animated
              withCompletionHandler:(void (^)(void))completionHandler;

- (void)setUpAccountsPicker;
- (void)toggleAccountsPickerVisibility:(BOOL)visible
                              animated:(BOOL)animated
                 withCompletionHandler:(void (^)(void))completionHandler;
- (void)updateAccountsPickerAnimated:(BOOL)animated
               withCompletionHandler:(void (^)(void))completionHandler;

@end

@implementation NBAccountsViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IsSignedInKeyPath = @"signedIn";
        SelectedAccountKeyPath = NSStringFromSelector(@selector(selectedAccount));
    });
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"title.nationbuilder-accounts".nb_localizedString;
        self.shouldAutoPromptForNationSlug = YES;
    }
    return self;
}

- (void)dealloc
{
    self.containingPopoverController = nil;
}

#pragma mark - NBLogging

+ (void)updateLoggingToLevel:(NBLogLevel)logLevel
{
    LogLevel = logLevel;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (!self.isPresentedInPopover) {
        self.navigationItem.leftBarButtonItem = self.closeButtonItem;
    }
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.logoImageView.image = [self.logoImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.logoImageView.tintColor = self.buttonBackgroundColor;
    [self setUpAccountView];
    [self setUpActionButtons];
    [self setUpAccountsPicker];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSAssert(self.dataSource, @"Data source must be set before appearance.");
    [self updateAccountViewAnimated:NO withCompletionHandler:nil];
    [self updateActionButtonsAnimated:NO withCompletionHandler:nil];
    [self updateAccountsPickerAnimated:NO withCompletionHandler:nil];
    // Customize title view.
    self.navigationController.navigationBar.titleTextAttributes =
    @{ NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody] };
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.shouldAutoPromptForNationSlug && !self.dataSource.isSignedIn) {
        [self promptForNationSlug];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.nationSlugPromptView.isVisible) {
        [self.nationSlugPromptView dismissWithClickedButtonIndex:self.nationSlugPromptView.cancelButtonIndex
                                                        animated:animated];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    // Re-showing an alert after it adjusts for auto-rotation causes it to have layout problems. So reset it instead.
    [self.nationSlugPromptView dismissWithClickedButtonIndex:self.nationSlugPromptView.cancelButtonIndex animated:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nationSlugPromptView = nil;
    });
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (self.isPresentedInPopover) {
        [self.containingPopoverController dismissPopoverAnimated:YES];
    } else if (self.presentingViewController &&
               [self.presentingViewController isKindOfClass:[UINavigationController class]] &&
               [(id)self.presentingViewController visibleViewController] == self) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.nationSlugPromptView && buttonIndex != alertView.cancelButtonIndex) {
        __block NSError *error;
        NSString *nationSlug = [alertView textFieldAtIndex:0].text;
        BOOL didAdd = [self.dataSource addAccountWithNationSlug:nationSlug error:&error];
        if (!didAdd) {
            // Work around the fact automatic alert dismissal can't be prevented.
            self.nationSlugErrorView = [UIAlertView nb_genericAlertViewWithError:error];
            self.nationSlugErrorView.delegate = self;
            [self.nationSlugErrorView show];
        }
    } else if (alertView == self.nationSlugErrorView) {
        [self promptForNationSlug];
    } else if (buttonIndex != alertView.cancelButtonIndex){
        NBLogWarning(@"Unhandled case.");
    }
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender
{
    if (sender == self.closeIconButton || !sender) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        NBLogWarning(@"Unhandled sender %@", sender);
    }
}

- (IBAction)signIn:(id)sender {
    [self promptForNationSlug];
}

- (IBAction)signOut:(id)sender {
    NSError *error;
    if ([self.dataSource signOutWithError:&error]) {
        if (!self.dataSource.isSignedIn) {
            [self didSignOutOfLastAccount];
        }
    } else {
        [[UIAlertView nb_genericAlertViewWithError:error] show];
    }
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != &observationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if (object == self.dataSource) {
        if ([keyPath isEqual:IsSignedInKeyPath]) {
            [self updateAccountViewAnimated:YES withCompletionHandler:^{
                [self updateActionButtonsAnimated:YES withCompletionHandler:^{
                    [self updateAccountsPickerAnimated:YES withCompletionHandler:nil];
                }];
            }];
        } else if ([keyPath isEqual:SelectedAccountKeyPath]) {
            [self updateAccountViewAnimated:YES withCompletionHandler:^{
                [self updateAccountsPickerAnimated:YES withCompletionHandler:nil];
            }];
        }
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return (NSInteger)self.dataSource.accounts.count;
}

#pragma mark - UIPickerViewDelegate

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return self.originalSignOutButtonHeight;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    static NSString *emSpace = @" ";
    id<NBAccountViewDataSource> account = self.dataSource.accounts[(NSUInteger)row];
    NSString *title = [NSString stringWithFormat:@"%@%@%@", account.name, emSpace, account.nationSlug];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [attributedTitle addAttributes:@{ NSFontAttributeName: self.nationLabel.font,
                                      NSForegroundColorAttributeName: self.nationLabel.textColor }
                             range:[title rangeOfString:account.nationSlug]];
    return [[NSAttributedString alloc] initWithAttributedString:attributedTitle];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = self.nameLabel.font;
        label.textAlignment = NSTextAlignmentCenter;
    }
    label.attributedText = [self pickerView:pickerView attributedTitleForRow:row forComponent:component];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // NOTE: Only called on user-interaction-driven selection, so there's no
    // infinite loop.
    // Raise our flag before having the view interaction update state, so as to
    // distinguish from state being updated by our data source.
    self.selectingAccount = YES;
    id<NBAccountViewDataSource> account = self.dataSource.accounts[(NSUInteger)row];
    self.dataSource.selectedAccount = account;
}

#pragma mark - Public

- (void)promptForNationSlug
{
    UITextField *textField = [self.nationSlugPromptView textFieldAtIndex:0];
    // NOTE: The alignment bug in iOS 7 is framework-level and fixed in 8.
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    if (self.dataSource.selectedAccount) {
        textField.text = nil;
    } else {
        textField.text = self.dataSource.previousAccountNationSlug;
    }
    [self.nationSlugPromptView show];
}

- (void)showWithAccountButton:(NBAccountButton *)accountButton
     presentingViewController:(UIViewController *)presentingViewController
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.presentedInPopover = YES;
        // NOTE: Popover controllers need to be retained.
        if (accountButton.barButtonItem) {
            [self.containingPopoverController presentPopoverFromBarButtonItem:accountButton.barButtonItem
                                                     permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            [self.containingPopoverController presentPopoverFromRect:accountButton.frame inView:accountButton
                                            permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
        [presentingViewController presentViewController:navigationController animated:YES completion:nil];
        // Avoid black background beneath translucent navigation bar.
        navigationController.view.backgroundColor = presentingViewController.view.backgroundColor;
    }
    // Save for dismissal.
    self.customPresentingViewController = presentingViewController;
}

#pragma mark Accessors

- (void)setDataSource:(id<NBAccountsViewDataSource>)dataSource
{
    // Tear down.
    if (self.dataSource) {
        [(id)self.dataSource removeObserver:self forKeyPath:IsSignedInKeyPath context:&observationContext];
        [(id)self.dataSource removeObserver:self forKeyPath:SelectedAccountKeyPath context:&observationContext];
    }
    // Set.
    _dataSource = dataSource;
    // Set up.
    if (self.dataSource) {
        [(id)self.dataSource addObserver:self forKeyPath:IsSignedInKeyPath options:0 context:&observationContext];
        [(id)self.dataSource addObserver:self forKeyPath:SelectedAccountKeyPath options:0 context:&observationContext];
    }
}

#pragma mark - Private

- (void)didSignOutOfLastAccount
{
    [self toggleAccountViewVisibility:NO animated:YES withCompletionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.shouldAutoPromptForNationSlug) {
                [self promptForNationSlug];
            } else {
                [self dismiss:nil];
            }
        });
    }];
}

- (void)updateVisibilityForSubview:(UIView *)subview
                           visible:(BOOL)visible
                          animated:(BOOL)animated
             withCompletionHandler:(void (^)(void))completionHandler
{
    if (animated) {
        [self.view setNeedsUpdateConstraints];
        if (visible) {
            subview.hidden = NO;
        }
        [UIView
         animateWithDuration:self.appearanceDuration.floatValue delay:0.0f
         options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
         animations:^{ [self.view layoutIfNeeded]; }
         completion:^(BOOL finished) {
             if (!visible) {
                 subview.hidden = YES;
             }
             if (completionHandler) {
                 completionHandler();
             }
         }];
    } else {
        [subview layoutIfNeeded];
        if (completionHandler) { completionHandler(); }
    }
}

#pragma mark Accessors

- (UIBarButtonItem *)closeButtonItem
{
    if (_closeButtonItem) {
        return _closeButtonItem;
    }
    self.closeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.closeIconButton];
    return _closeButtonItem;
}

- (UIButton *)closeIconButton
{
    if (_closeIconButton) {
        return _closeIconButton;
    }
    static NSString *closeIcon = @"\ue680";
    self.closeIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeIconButton.titleLabel.font = [UIFont fontWithName:NBIconFontFamilyName size:44.0f];
    [self.closeIconButton setTitle:closeIcon forState:UIControlStateNormal];
    [self.closeIconButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeIconButton sizeToFit];
    return _closeIconButton;
}

- (UIAlertView *)nationSlugPromptView
{
    if (_nationSlugPromptView) {
        return _nationSlugPromptView;
    }
    self.nationSlugPromptView =
    [[UIAlertView alloc] initWithTitle:@"title.provide-nation-slug".nb_localizedString
                               message:@"message.nation-slug-hint".nb_localizedString
                              delegate:self
                     cancelButtonTitle:@"label.cancel".nb_localizedString
                     otherButtonTitles:@"label.submit".nb_localizedString, nil];
    self.nationSlugPromptView.alertViewStyle = UIAlertViewStylePlainTextInput;
    return _nationSlugPromptView;
}

- (UIPopoverController *)containingPopoverController
{
    if (_containingPopoverController) {
        return _containingPopoverController;
    }
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self];
    self.containingPopoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    return _containingPopoverController;
}

- (NSUInteger)selectedIndex
{
    if (!self.dataSource || !self.dataSource.selectedAccount) {
        return NSNotFound;
    }
    return [self.dataSource.accounts indexOfObject:self.dataSource.selectedAccount];
}

#pragma mark Account View

- (void)setUpAccountView
{
    self.originalAccountViewHeight = self.accountViewHeight.constant;
    self.originalAccountViewBottomMargin = self.accountViewBottomMargin.constant;
    // Style appearance.
    self.accountView.layer.borderWidth = 1.0f;
    self.accountView.layer.borderColor = self.borderColor.CGColor;
    self.accountView.layer.cornerRadius = self.cornerRadius.floatValue;
    self.avatarImageView.layer.borderWidth = 1.0f;
    self.avatarImageView.layer.borderColor = self.imageBorderColor.CGColor;
    self.avatarImageView.layer.cornerRadius = self.imageCornerRadius.floatValue;
}

- (void)toggleAccountViewVisibility:(BOOL)visible
                           animated:(BOOL)animated
              withCompletionHandler:(void (^)(void))completionHandler
{
    CGFloat newHeight = visible ? self.originalAccountViewHeight : 0.0f;
    if (animated) {
        animated = newHeight != self.accountViewHeight.constant;
    }
    self.accountViewHeight.constant = newHeight;
    self.accountViewBottomMargin.constant  = visible ? self.originalAccountViewBottomMargin : 0.0f;
    [self updateVisibilityForSubview:self.accountView visible:visible animated:animated withCompletionHandler:completionHandler];
}

- (void)updateAccountViewAnimated:(BOOL)animated
            withCompletionHandler:(void (^)(void))completionHandler
{
    id<NBAccountViewDataSource> dataSource = self.dataSource.selectedAccount;
    if (dataSource) {
        self.nameLabel.text = dataSource.name;
        self.nationLabel.text = dataSource.nationSlug;
        self.avatarImageView.image = [UIImage imageWithData:dataSource.avatarImageData];
    }
    [self toggleAccountViewVisibility:self.dataSource.isSignedIn animated:animated withCompletionHandler:completionHandler];
}

#pragma mark Action Buttons

- (void)setUpActionButtons
{
    self.originalSignOutButtonHeight = self.signOutButtonHeight.constant;
    self.originalSignOutButtonTopMargin = self.signOutButtonTopMargin.constant;
    // Style appearance.
    self.signOutButton.backgroundColor = self.buttonBackgroundColor;
    self.signOutButton.layer.cornerRadius = self.cornerRadius.floatValue;
    self.addAccountButton.backgroundColor = self.buttonBackgroundColor;
    self.addAccountButton.layer.cornerRadius = self.cornerRadius.floatValue;
}

- (void)toggleSignOutButtonVisibility:(BOOL)visible
                             animated:(BOOL)animated
                withCompletionHandler:(void (^)(void))completionHandler
{
    CGFloat newHeight = visible ? self.originalSignOutButtonHeight : 0.0f;
    if (animated) {
        animated = newHeight != self.signOutButtonHeight.constant;
    }
    self.signOutButtonHeight.constant = newHeight;
    self.signOutButtonTopMargin.constant = visible ? self.originalSignOutButtonTopMargin : 0.0f;
    [self updateVisibilityForSubview:self.signOutButton visible:visible animated:animated withCompletionHandler:completionHandler];
}

- (void)updateActionButtonsAnimated:(BOOL)animated
              withCompletionHandler:(void (^)(void))completionHandler
{
    [self toggleSignOutButtonVisibility:self.dataSource.isSignedIn animated:animated withCompletionHandler:completionHandler];
    [self.addAccountButton setTitle:(self.dataSource.isSignedIn ? @"label.sign-into-another" : @"label.sign-in").nb_localizedString
                           forState:UIControlStateNormal];
}

#pragma mark Account Picker

- (void)setUpAccountsPicker
{
    self.originalAccountsPickerHeight = self.accountsPickerHeight.constant;
    self.originalAccountsPickerBottomMargin = self.accountsPickerBottomMargin.constant;
    // Style appearance.
    self.accountsPicker.layer.borderWidth = 1.0f;
    self.accountsPicker.layer.borderColor = self.borderColor.CGColor;
    self.accountsPicker.layer.cornerRadius = self.cornerRadius.floatValue;
}

- (void)toggleAccountsPickerVisibility:(BOOL)visible
                              animated:(BOOL)animated
                 withCompletionHandler:(void (^)(void))completionHandler
{
    CGFloat newHeight = visible ? self.originalAccountsPickerHeight : 0.0f;
    if (animated) {
        animated = newHeight != self.accountsPickerHeight.constant;
    }
    self.accountsPickerHeight.constant = newHeight;
    self.accountsPickerBottomMargin.constant = visible ? self.originalAccountsPickerBottomMargin : 0.0f;
    [self updateVisibilityForSubview:self.accountsPickerContainer visible:visible animated:animated withCompletionHandler:completionHandler];
}

- (void)updateAccountsPickerAnimated:(BOOL)animated
               withCompletionHandler:(void (^)(void))completionHandler
{
    [self.accountsPicker reloadAllComponents];
    [self toggleAccountsPickerVisibility:(self.dataSource.accounts.count > 1) animated:animated withCompletionHandler:^{
        // Update selected row.
        if (!self.isSelectingAccount && self.dataSource.selectedAccount) {
            // Only update the picker if it did not trigger the account selection.
            NSUInteger selectedIndex = [self selectedIndex];
            if (selectedIndex == NSNotFound) {
                NBLogError(@"Invalid selected account index. Aborting row selection.");
            }
            [self.accountsPicker selectRow:(NSInteger)selectedIndex inComponent:0 animated:YES];
        } else {
            // Otherwise restore our flag.
            self.selectingAccount = NO;
        }
    }];
}

@end

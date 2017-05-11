/*
 * Endless
 * Copyright (c) 2015 joshua stein <jcs@jcs.org>
 *
 * See LICENSE file for redistribution terms.
 */

#import "SSLCertificateViewController.h"

@implementation SSLCertificateViewController

#define CI_SIGALG_KEY NSLocalizedString(@"Signature Algorithm", @"Field name for display in list")
#define CI_EVORG_KEY NSLocalizedString(@"Extended Validation: Organization", @"Field name for display in list")

- (id)initWithSSLCertificate:(SSLCertificate *)cert
{
	self = [super init];
	[self setCertificate:cert];

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done action button. dismisses SSL certificate information dialog") style:UIBarButtonItemStyleDone target:self.navigationController action:@selector(dismissModalViewControllerAnimated:)];

	certInfo = [[MutableOrderedDictionary alloc] init];

	MutableOrderedDictionary *i;

	if ([cert negotiatedProtocol]) {
		i = [[MutableOrderedDictionary alloc] init];
		[i setObject:[cert negotiatedProtocolString] forKey:NSLocalizedString(@"Protocol", @"Field name for display in list")];
		[i setObject:[cert negotiatedCipherString] forKey:NSLocalizedString(@"Cipher", @"Field name for display in list")];
		[certInfo setObject:i forKey:NSLocalizedString(@"Connection Information", @"Field name for display in list")];
	}

	i = [[MutableOrderedDictionary alloc] init];
	[i setObject:[NSString stringWithFormat:@"%@", [cert version]] forKey:NSLocalizedString(@"Version", @"Field name for display in list")];
	[i setObject:[cert serialNumber] forKey:NSLocalizedString(@"Serial Number", @"Field name for display in list")];
	[i setObject:[cert signatureAlgorithm] forKey:CI_SIGALG_KEY];
	if ([cert isEV])
		[i setObject:[cert evOrgName] forKey:CI_EVORG_KEY];
	[certInfo setObject:i forKey:NSLocalizedString(@"Certificate Information", @"Field name for display in list")];

	NSDictionary<NSString*,NSString*> *localizedKeys = @{
														 X509_KEY_CN:X509_KEY_CN_l10n,
														 X509_KEY_O:X509_KEY_O_l10n,
														 X509_KEY_OU:X509_KEY_OU_l10n,
														 X509_KEY_STREET:X509_KEY_STREET_l10n,
														 X509_KEY_L:X509_KEY_L_l10n,
														 X509_KEY_ST:X509_KEY_ST_l10n,
														 X509_KEY_ZIP:X509_KEY_ZIP_l10n,
														 X509_KEY_C:X509_KEY_C_l10n,
														 X509_KEY_BUSCAT:X509_KEY_BUSCAT_l10n,
														 X509_KEY_SERIAL:X509_KEY_SERIAL_l10n,
														 X509_KEY_SN:X509_KEY_SN_l10n
														 };

	i = [[MutableOrderedDictionary alloc] init];
	NSMutableDictionary *tcs = [[NSMutableDictionary alloc] initWithDictionary:[cert subject]];
	for (NSString *k in @[ X509_KEY_CN, X509_KEY_O, X509_KEY_OU, X509_KEY_STREET, X509_KEY_L, X509_KEY_ST, X509_KEY_ZIP, X509_KEY_C ]) {
		NSString *val = [tcs objectForKey:k];
		if (val != nil) {
			[i setObject:val forKey:(NSString*)[localizedKeys objectForKey:k]];
			[tcs removeObjectForKey:k];
		}
	}
	for (NSString *k in [tcs allKeys]) {
		NSString *localizedKey = (NSString*)[localizedKeys objectForKey:k];
		[i setObject:[[cert subject] objectForKey:k] forKey:localizedKey != nil ? localizedKey : k];
	}
	[certInfo setObject:i forKey:NSLocalizedString(@"Issued To", @"Field name for display in list")];

	NSDateFormatter *df_local = [[NSDateFormatter alloc] init];
	[df_local setTimeZone:[NSTimeZone defaultTimeZone]];
	[df_local setDateFormat:[NSString stringWithFormat:@"%@", NSLocalizedString(@"yyyy-MM-dd 'at' HH:mm:ss zzz", "This string will end up as '<date> 'at' <time>'. For example 2016-03-01 at 19:00:00 EST. Only 'at' should be translated with apostrophes preserved and the date and time strings placed where appropriate.")]];

	i = [[MutableOrderedDictionary alloc] init];
	[i setObject:[df_local stringFromDate:[cert validityNotBefore]] forKey:NSLocalizedString(@"Begins On", @"Field name for display in list")];
	[i setObject:[df_local stringFromDate:[cert validityNotAfter]] forKey:NSLocalizedString(@"Expires After", @"Field name for display in list")];
	[certInfo setObject:i forKey:NSLocalizedString(@"Period of Validity", @"Field name for display in list")];

	i = [[MutableOrderedDictionary alloc] init];

	NSMutableDictionary *tci = [[NSMutableDictionary alloc] initWithDictionary:[cert issuer]];
	for (NSString *k in @[ X509_KEY_CN, X509_KEY_O, X509_KEY_OU, X509_KEY_STREET, X509_KEY_L, X509_KEY_ST, X509_KEY_ZIP, X509_KEY_C ]) {
		NSString *val = [tci objectForKey:k];
		if (val != nil) {
			[i setObject:val forKey:(NSString*)[localizedKeys objectForKey:k]];
			[tci removeObjectForKey:k];
		}
	}
	for (NSString *k in [tci allKeys]) {
		NSString *localizedKey = (NSString*)[localizedKeys objectForKey:k];
		[i setObject:[[cert issuer] objectForKey:k] forKey:localizedKey != nil ? localizedKey : k];
	}
	[certInfo setObject:i forKey:NSLocalizedString(@"Issued By", @"Field name for display in list")];

	return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [certInfo count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [certInfo keyAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	OrderedDictionary *group = [certInfo objectAtIndex:section];
	return [group count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];

	OrderedDictionary *group = [certInfo objectAtIndex:[indexPath section]];
	NSString *k = [group keyAtIndex:[indexPath row]];

	cell.textLabel.text = k;
	cell.detailTextLabel.text = [group objectForKey:k];

	if ([k isEqualToString:CI_SIGALG_KEY] && [[self certificate] hasWeakSignatureAlgorithm])
		cell.detailTextLabel.textColor = [UIColor redColor];
	else if ([k isEqualToString:CI_EVORG_KEY])
		cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:(183.0/255.0) blue:(82.0/255.0) alpha:1.0];

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

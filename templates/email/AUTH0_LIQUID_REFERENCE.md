# Auth0 Email Templates — Supported Liquid Syntax

**Purpose:** Reference guide for creating and modifying Auth0 email templates using Liquid syntax.

**Official documentation:** https://auth0.com/docs/customize/email/email-templates/supported-liquid-syntax

## 1. Liquid Syntax Basics

Auth0 email templates support LiquidJS syntax for dynamic content and conditional rendering.

### Output expressions

Use `{{ ... }}` to output a variable or a value.

```liquid
Hello, {{ user.name }}
```

Apply filters using the pipe (`|`) operator:

```liquid
{{ user.name | escape }}
```

### Logic and control tags

Use `{% ... %}` to implement conditions, loops, and other template logic.

```liquid
{% if user_metadata.lang == 'it' %}
  Ciao!
{% else %}
  Hello!
{% endif %}
```

**Important distinction:**
- `{{ ... }}` outputs a value.
- `{% ... %}` executes template logic without directly outputting the tag itself.

## 2. Supported Liquid Tags

Auth0 email templates support the following tags.

| Category | Supported tags |
|---|---|
| Iteration | `for`, `cycle`, `tablerow` |
| Control flow | `if`, `unless`, `elsif`, `else`, `case` |
| Variables | `assign`, `increment`, `decrement` |
| Files and layouts | `include`, `layout` |
| Language and debugging | `raw`, `comment`, `debug` |

### Examples

**Conditional rendering**

```liquid
{% if user.email_verified %}
  Your email is verified.
{% else %}
  Please verify your email address.
{% endif %}
```

**Assigning a variable**

```liquid
{% assign display_name = user.given_name %}
Hello, {{ display_name | escape }}!
```

**Iterating over a collection**

```liquid
{% for role in roles %}
  {{ role.name | escape }}
{% endfor %}
```

The variables available inside a loop depend on the data supplied to the template.

### Debug tag

Auth0 provides a custom `{% debug %}` tag that outputs a summary of the template variables available during rendering.

Use it for development and troubleshooting, not as part of a production email.

## 3. Supported Liquid Filters

Filters transform values before they are output. Chain filters using the pipe operator.

### Mathematical filters

`plus`, `minus`, `modulo`, `times`, `floor`, `ceil`, `round`, `divided_by`, `abs`, `at_least`, `at_most`

Example:

```liquid
{{ 10 | plus: 5 }}
```

Result: `15`

### String filters

`append`, `prepend`, `capitalize`, `upcase`, `downcase`, `strip`, `lstrip`, `rstrip`, `strip_newlines`, `split`, `replace`, `replace_first`, `remove`, `remove_first`, `truncate`, `truncatewords`

Examples:

```liquid
{{ user.name | capitalize }}
{{ user.nickname | append: "!" }}
{{ user.name | truncate: 30 }}
```

### HTML and URI filters

`escape`, `escape_once`, `url_encode`, `url_decode`, `strip_html`, `newline_to_br`

Examples:

```liquid
{{ user.name | escape }}
{{ custom_domain.domain | url_encode }}
```

Use `escape` when outputting untrusted user-controlled data in HTML.

### Array filters

`slice`, `map`, `sort`, `sort_natural`, `first`, `last`, `join`, `reverse`, `size`

Examples:

```liquid
{{ roles | size }}
{{ roles | map: "name" | join: ", " }}
```

These examples assume that the corresponding variables contain compatible arrays or collections.

### Date filter

`date`

Example:

```liquid
{{ some_date | date: "%Y-%m-%d" }}
```

The variable must contain a value that the date filter can process.

### Miscellaneous filters

`default`

Example:

```liquid
{{ user.given_name | default: "there" }}
```

This provides a fallback value when the input is empty or otherwise considered blank by the filter.

For complete filter syntax and behavior, consult the LiquidJS filters reference linked from the official Auth0 documentation.

## 4. General Variables

The following variables are available in the **From Address, Subject, and Message fields** of email templates, subject to the restrictions described below.

### Application object

| Variable | Description |
|---|---|
| `application.name` | Application name |
| `application.client_metadata` | Application client metadata |

The `application` object also exposes standard client properties.

### Request language

| Variable | Description |
|---|---|
| `request_language` | Language selected for the user |

### Connection

| Variable | Description |
|---|---|
| `connection.name` | Name of the authentication connection |

**Restriction:** `connection.name` is unavailable in the MFA enrollment email template.

### Tenant variables

Tenant-related information configured in Auth0 Tenant Settings:

| Variable | Description |
|---|---|
| `tenant` | Raw tenant name |
| `friendly_name` | Friendly tenant name |
| `support_email` | Support email address |
| `support_url` | Support URL |

### User variables

| Variable | Description | Trust considerations |
|---|---|---|
| `user.email` | User email address | Treat according to the context in which it is used |
| `user.email_verified` | Whether the email address is verified | Boolean-like verification state |
| `user.picture` | User profile picture | Untrusted |
| `user.nickname` | User nickname | Untrusted |
| `user.given_name` | User's given name | Untrusted |
| `user.family_name` | User's family name | Untrusted |
| `user.name` | User's name | Untrusted |
| `user.app_metadata` | Application-related user attributes | May affect functionality, roles, and access |
| `user.user_metadata` | User attributes such as preferences | Untrusted when it contains user-provided information |

`app_metadata` can contain information such as support plans, security roles, and access control groups. `user_metadata` is intended for attributes that do not affect core functionality, such as user preferences.

**Passwordless OTP restriction:** In the Passwordless OTP email template, only the `email` property of the `user` object is available.

### Organization variables

When a user logs in through an Auth0 Organization, the following additional variables are available:

| Variable | Description |
|---|---|
| `organization.id` | Organization identifier |
| `organization.display_name` | Organization display name |
| `organization.name` | Organization name |
| `organization.metadata` | Organization metadata |
| `organization.branding.logo_url` | Organization branding logo URL |
| `organization.branding.colors.primary` | Primary branding color |
| `organization.branding.colors.page_background` | Page background color |

These variables are available in the organization-login context described by Auth0.

### Custom domain variables

| Variable | Description |
|---|---|
| `custom_domain.domain` | Custom domain currently being used, such as `login.example.com` |
| `custom_domain.domain_metadata` | Key-value metadata associated with the custom domain |

These variables can be used to customize email content based on the domain that triggered the email.

Example:

```liquid
{% if custom_domain.domain_metadata.brand == "BrandA" %}
  <h1 style="color: #0000FF;">Welcome to Brand A</h1>
{% elsif custom_domain.domain_metadata.brand == "BrandB" %}
  <h1 style="color: #FF0000;">Welcome to Brand B</h1>
{% else %}
  <h1>Welcome</h1>
{% endif %}
```

Example of selecting support contact information:

```liquid
{% if custom_domain.domain_metadata.support_email %}
  <p>
    Need help? Contact us at
    {{ custom_domain.domain_metadata.support_email | escape }}
  </p>
{% else %}
  <p>
    Need help? Contact us at {{ support_email | escape }}
  </p>
{% endif %}
```

To use custom domains in emails:

1. Configure and verify your custom domains.
2. Enable **Use Custom Domain in Emails** under Dashboard → Branding → Custom Domains.
3. Set a default custom domain when using multiple custom domains.

Auth0 automatically uses the appropriate custom domain for email links when multiple custom domains are configured and the required settings are enabled.

## 5. Redirect To Variables

For email templates that contain a **Redirect To URL** field, only the following variables are supported:

| Variable | Alias | Description |
|---|---|---|
| `application.name` | `client.name` | Application name |
| `application.clientID` | None specified | Application client ID |
| `application.callback_domain` | `client.callback_domain` | Origin of the first URL in the application's Allowed Callback URLs list |

Example:

```liquid
{{ application.callback_domain }}/result_page
```

The callback domain includes the protocol, such as `https://`, because it represents the URL origin.

**Availability restriction:** Custom Redirect To values are unavailable on non-enterprise tenants created on or after May 5, 2026. Check Auth0's current URL Lifetime and Redirect To documentation for the applicable restrictions.

Do not assume that every variable available in the email message is also available in the Redirect To field.

## 6. Template-Specific Variables

Some email templates expose additional variables beyond the general variables listed above.

### Blocked account email

| Variable | Description |
|---|---|
| `user.source_ip` | User's source IP address |
| `user.city` | User's city |
| `user.country` | User's country |
| `url` | Account unblock link |

### Change password — code template

| Variable | Description |
|---|---|
| `code` | Password change code |

### Change password — link template

| Variable | Description |
|---|---|
| `url` | Password reset link |

### MFA enrollment email

| Variable | Description |
|---|---|
| `link` | MFA enrollment link |

Remember that `connection.name` is not available in this template.

### Passwordless OTP email

| Variable | Description |
|---|---|
| `send` | Indicates the requested passwordless delivery type |
| `code` | One-time-use access code |
| `link` | Access link, available for link-type passwordless emails |
| `operation` | Indicates an email change operation when its value is `change_email` |

The `send` variable can have these values:

- `link`
- `link_ios`
- `link_android`
- `code`

Only use `link` when the requested email is a link-type passwordless email.

### User invitation email

| Variable | Description |
|---|---|
| `inviter.name` | Name of the person sending the invitation |
| `roles.id` | Role identifier |
| `roles.name` | Role name |
| `roles.description` | Role description |

### Verification email — code template

| Variable | Description |
|---|---|
| `code` | Email verification code |

### Verification email — link template

| Variable | Description |
|---|---|
| `url` | Email verification link |

## 7. Security and Implementation Guidelines

Follow these guidelines when creating or modifying Auth0 email templates.

### Escape untrusted values

Auth0 explicitly recommends escaping untrusted properties using the `escape` filter.

Recommended:

```liquid
{{ user.name | escape }}
```

Avoid directly inserting untrusted values into HTML without escaping:

```liquid
{{ user.name }}
```

The second example is not appropriate when the value may contain user-controlled HTML characters.

Apply the same caution to user metadata and other untrusted properties.

### Check variable availability

Do not assume every variable exists in every email template. Availability depends on the email template type and rendering context.

For example:

- `connection.name` is unavailable in MFA enrollment emails.
- Only `user.email` is available from the `user` object in Passwordless OTP emails.
- Template-specific variables such as `url`, `code`, and `link` are available only in their applicable templates.
- Redirect To fields support a smaller set of variables than general email fields.

### Use fallbacks when appropriate

```liquid
{{ user.given_name | default: "there" | escape }}
```

This is useful when a user does not have a usable given name.

### Verify custom domain configuration

When an email uses domain-specific branding or support information, confirm that the custom domain is configured, verified, enabled for emails, and assigned as the default where required.

### Validate the rendered output

Test templates using representative values and relevant scenarios, including missing optional values, untrusted user-provided strings, conditional branches, and the exact email template type.

## 8. Quick Reference

| Requirement | Syntax |
|---|---|
| Output a variable | `{{ user.email }}` |
| Escape HTML-sensitive characters | `{{ user.name \| escape }}` |
| Add a condition | `{% if condition %}...{% endif %}` |
| Add an alternative condition | `{% elsif condition %}` |
| Add a fallback branch | `{% else %}` |
| Assign a variable | `{% assign name = value %}` |
| Apply a filter | `{{ value \| filter_name }}` |
| Provide a default | `{{ user.given_name \| default: "there" }}` |
| Inspect available template variables during debugging | `{% debug %}` |

## 9. Instructions for AI Assistants Working With Auth0 Templates

When generating or editing Auth0 email templates:

1. Use only Liquid tags, filters, and variables supported by the Auth0 documentation.
2. Confirm that each variable is available in the specific email template being modified.
3. Do not use general email variables in Redirect To fields unless they are explicitly supported there.
4. Escape untrusted user-controlled properties before inserting them into HTML.
5. Preserve the intended email behavior, authentication flow, and required verification or password-reset links.
6. Do not invent Auth0 variables or assume that undocumented LiquidJS features are supported.
7. Use conditional logic and default values when optional data may be missing.
8. If a requirement depends on undocumented behavior, identify the uncertainty and consult the official Auth0 documentation rather than guessing.
9. Distinguish documented Auth0 behavior from examples or implementation assumptions.
10. Test the rendered template and relevant edge cases before treating the implementation as production-ready.

**Primary reference:** https://auth0.com/docs/customize/email/email-templates/supported-liquid-syntax

**Additional references linked by Auth0:**
- LiquidJS introduction: https://liquidjs.com/
- LiquidJS tags reference: https://liquidjs.com/tags/overview.html
- LiquidJS filters reference: https://liquidjs.com/filters/overview.html

Use the official Auth0 documentation as the source of truth for Auth0-specific restrictions and availability.

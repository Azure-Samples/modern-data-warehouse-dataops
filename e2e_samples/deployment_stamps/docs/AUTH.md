# Authentication and Authorization

This sample uses Azure AD as identity provider. You need to:

- Provision Azure AD (or use existing one)
- Add users and groups
- Register an application
  - Setup authentication
  - Setup expose an api
  - Setup application roles
  - Setup API permission
- Setup Users and groups in Enterprise Application

## Provision Azure AD

If you don't have any Azure AD yet or need to create new one for testing, follow [Create a new tenant in Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-access-create-new-tenant) to provision one.

## Add users and groups

### Users

To test the application, you need at least one user. You can use your own account or create new one.

To create a new user, follow [Add or delete users using Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/add-users-azure-active-directory).

### Groups

To test the application, you need two groups.

- A group for admin
- A group for user

You can name them as you want.

To create a new Group, follow [Create a basic group and add members using Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-groups-create-azure-portal#create-a-basic-group-and-add-members).

## Register an application

Follow the steps below to register new application.

1. Go to "App registrations" menu in Azure AD portal.

1. Click "New registration".

1. Enter any name, and click "Register" with default configuration.

## Setup authentication

Once you setup an application, you need to setup authentication.

1. In the newly registered App's page, select "Authentication" menu and click "Add a platform".
1. Select "Web" and enter redirect URIs of your server. If you want to debug locally, it would be `https://localhost:<port>/signin-oidc`. If you deploy the app to Azure WebApp, use the web app URL and add "/signin-oidc" at the end.
1. Click "Configure".

### Setup Expose an API

1. Click "Expose an API" menu.
1. Click "Add a scope".
1. Click "Save and configure" with default settings.
1. Enter "access_as_user" for scope name and enter any display name/description.
1. Click "Add scope".

### Setup application roles

1. Click "App roles".
1. Click "Create app role" button.
1. Enter "Tenant Administrator" as display name.
1. Select "Both(Users/Groups + Applications) for member type.
1. Enter "TenantAdministrator" to Value without space.
1. Enter any description and create the role.
1. Repeat the steps to create "User" role.

### Setup API permission

1. Select "API permission".
1. Click "Add permission".
1. Select "My APIs" and select registered application.
1. Select "Delegated permissions".
1. Select "access_as-user" and click "Add permission.
1. You need to add application permission as well. Click "Add permission".
1. Select "My APIs" and select registered application.
1. Select "Application permissions".
1. Select both "TenantAdministrator" and "User" permission.
1. Click add permission.
1. Click "Grant admin consent for your domain name".
1. Confirm status becomes all green for all permissions.

The application permission are used for integration test account. Scope for these application permission is api://<client_id>/.default.

## Setup Users and groups in Enterprise Application

Once you register an application, you can map app role and groups.

1. Go to Azure AD portal and select "Enterprise Applications".
1. Select created application from the list.
1. Select "Users and groups" menu.
1. Click "Add user/group".
1. Select existing group for admin and select "Tenant Administrator" role. This maps a group to an app role.
1. Click "Assign".
1. Repeat the steps for "User" role.

### Add Users to group

Once you setup group/app role mapping, you can now add users into groups.

1. Go to Azure Portal and select groups.
1. Select admin group and assign any users.
1. Also assign registered application to the group so that an integration test can use the application id as user. (You can create separate application for this purpose if you want.)
1. Repeat the step for user group.

To confirm the setup, use postman to test the Web API. See [POSTMAN readme](./POSTMAN.md) for detail.

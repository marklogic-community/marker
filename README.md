MarkLogic Marker 

All original code copyright MarkLogic 2010-2011 and is licensed via - http://www.apache.org/licenses/LICENSE-2.0.html

See https://github.com/marklogic/marker for a description of this project.

SETUP INSTRUCTIONS
1. Get the source from Github (where you might be reading this readme).

2. Install and run MarkLogic 4.2 (http://developer.marklogic.com/downloads)

3. Install cq and copy and paste "Admin-base-install.txt" contents into the query window. 
Edit the line that gives the directory of your marker repo.  Press text.

4. If successful you should see : Complete - please open your browser to http://localhost:8100 and login with your admin credentials

5. Open a browser to http://localhost:8100 and follow the on screen prompts
	a. to install security, click "Security has not been installed on this application. To continue, please click here to install"
	b. A modal prompt will ask you to verify via Facebook or github - this sets your account as the admin account
	c. after successfully logging in you will be placed back on the welcome screen
	d. you should see "plugins" on the sidebar with security -INSTALLED and marker - NOT INSTALLED
	e. click on marker - NOT INSTALLED
	f. to install marker, click "Marker has not been installed on this application. To continue, please click here to install."
	g. to install the sample data, click "Setup was successful for the marker plugin. Click here to install the sample data set"
	h. begin exploring the application


UNINSTALL INSTRUCTIONS
1. Open cq and copy and paste "Admin-base-uninstall.txt" contents into the query window. 
Adjust the usernames to match yours (assuming you want to remove them). Press text.

2. If necessary, you may need to go manually delete a forest named 'marker'

AUTHENTICATION NOTES
0. Whenever a user first authenticates, a tracking user account is created in 
MarkLogic and is given 'user' privs.

1. The first user to authenticate is also given 'admin' privs.

2. Authentication is done via OAuth2 and comes configured by default
to support a sample facebook and github applications.  These apps
are also configured to assume the OAuth2 redirect should go to http://localhost:8100

3. You should create your own github or facebook application if you want
authentication to be secure.

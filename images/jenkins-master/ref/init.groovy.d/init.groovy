import jenkins.model.*
import hudson.model.*
import hudson.security.*

def env = System.getenv()
def jenkins = Jenkins.getInstance()
def EXCLUSIVE = Node.Mode.valueOf('EXCLUSIVE')

// Allocate executors on master.
jenkins.setNumExecutors(env.MASTER_EXECUTORS as int)

// Only run tasks when node('master') is specifically requested
jenkins.setMode(EXCLUSIVE)

// Don't wait 5 seconds between stages (Quiet Period)
jenkins.setQuietPeriod(0)

// Mail setup
jenkins_loc = JenkinsLocationConfiguration.get()
jenkins_loc.setAdminAddress(env.SMTP_ADMIN_ADDRESS)
jenkins_loc.setUrl(env.JENKINS_URL)
jenkins_loc.save()
jenkins_mail = jenkins.getDescriptor('hudson.tasks.Mailer')
jenkins_mail.setSmtpHost(env.SMTP_SMARTHOST)
jenkins_mail.setDefaultSuffix('@' + \
    env.SMTP_SMARTHOST.tokenize('.').drop(1).join('.'))

// Users setup
jenkins.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
jenkins.setAuthorizationStrategy(new FullControlOnceLoggedInAuthorizationStrategy())

def realm = jenkins.getSecurityRealm()
realm.createAccount(env.JENKINS_ADMIN_USER, env.JENKINS_ADMIN_PASS).save()
realm.createAccount('jenkins', 'jenkins').save()

jenkins.save()

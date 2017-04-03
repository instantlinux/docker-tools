// credit goes to: https://github.com/foxylion/docker-jenkins
import jenkins.model.*
import hudson.security.*


def env = System.getenv()
def admin_user = env.JENKINS_DEFAULT_ADMIN_USER
def admin_pass = env.JENKINS_DEFAULT_ADMIN_PASS

def jenkins = Jenkins.getInstance()

jenkins.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
jenkins.setAuthorizationStrategy(new FullControlOnceLoggedInAuthorizationStrategy())

def realm = jenkins.getSecurityRealm()

realm.createAccount(admin_user, admin_pass).save()
realm.createAccount('jenkins', 'jenkins').save()

jenkins.save()

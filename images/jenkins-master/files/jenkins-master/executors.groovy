import jenkins.model.*
import hudson.model.*

def jenkins = Jenkins.getInstance()
def EXCLUSIVE = Node.Mode.valueOf('EXCLUSIVE')

// Allocate 4 executors on master.
jenkins.setNumExecutors(4)

// Only run tasks when node('master') is specifically requested
jenkins.setMode(EXCLUSIVE)

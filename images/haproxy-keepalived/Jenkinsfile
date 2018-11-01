#!/usr/bin/env groovy
// Pipeline for docker-image build
//  created by richb@instantlinux.net 20-apr-2017

node('swarm') {
    def buildDate = java.time.Instant.now().toString()
    def maintainer = 'richb@instantlinux.net'
    def registry = 'nexus.instantlinux.net'
    def registryCreds = [credentialsId: 'docker-registry',
                         url: "https://${registry}"]
    def service = env.JOB_NAME.split('/', 2)[0]

    try {
        stage('Static Code Analysis') {
            checkout scm
            sh "env ; cd images/${service} && make analysis"
        }
        stage('Create Image') {
            gitCommit = checkout(scm).GIT_COMMIT
            imageTag = "dev_build_${env.BUILD_NUMBER}_${gitCommit.take(7)}"
            img = docker.build("${registry}/${service}:${imageTag}",
                               "--build-arg=VCS_REF=${gitCommit} " +
                               "--build-arg=BUILD_DATE=${buildDate} " +
                               "images/${service}")
        }
        stage('Push Image') {
            withDockerRegistry(registryCreds) {
                img.push imageTag
            }
        }
        stage('Functional Tests') {
            withDockerRegistry(registryCreds) {
                dir("images/${service}") {
                    sh 'make test_functional'
                }
            }
        }
        stage('Promote Image') {
            withDockerRegistry(registryCreds) {
                img.push 'latest'
            }
        }
    }
    catch (Exception ex) {
        echo "Exception caught: ${ex.getMessage()}"
        currentBuild.result = 'FAILURE'
    }
    finally {
        currentBuild.result = currentBuild.result ?: 'SUCCESS'
        emailext (
            to: maintainer,
            subject: "Job ${env.JOB_NAME} #${env.BUILD_NUMBER} ${currentBuild.result}",
            body: "Build URL: ${env.BUILD_URL}.\nDocker Image ${registry}/${service}\n",
            attachLog: true
        )
        stage('Clean') {
            sh "docker rmi ${registry}/${service}:${imageTag}"
            deleteDir()
        }
    }
}

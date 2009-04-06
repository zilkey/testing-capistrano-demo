Feature: Deployment
  In order to know feel better about myself
  As a person who needs lots of reinforcement
  I want leave files named PEOPLE_LIKE_YOU all around my remote machine

  Scenario: User deploys
    Given a an app
    When I deploy
    Then the PEOPLE_LIKE_YOU file should be written to shared

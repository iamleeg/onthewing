Feature: Smoke Test

  Scenario: User loads the Main UI
    Given I navigate to the app root
    Then I should see the main application header and title

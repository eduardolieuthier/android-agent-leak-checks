package com.example.newsbulletin

import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.Espresso.pressBack
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.assertion.ViewAssertions.matches
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.runners.AndroidJUnit4
import leakcanary.LeakAssertions
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class LeakReproductionInstrumentationTest {
    @Test
    fun threeFollowPassagesAndAboutReturnDoNotRetainDestroyedActivities() {
        ActivityScenario.launch(HomeActivity::class.java).use {
            onView(withText("COMMUNITY GARDEN OPENS")).check(matches(isDisplayed()))
            onView(withText("LIBRARY ADDS EVENING HOURS")).check(matches(isDisplayed()))
            onView(withText("PARK TRAIL RESTORED")).check(matches(isDisplayed()))

            // Passage one: open the first article, follow updates, return and verify Home.
            onView(withText("COMMUNITY GARDEN OPENS")).perform(click())
            onView(withText("Community garden opens")).check(matches(isDisplayed()))
            onView(withId(R.id.followUpdatesButton)).perform(click())
            onView(withText("Following updates for this article.")).check(matches(isDisplayed()))
            pressBack()
            onView(withText("COMMUNITY GARDEN OPENS")).check(matches(isDisplayed()))
            onView(withText("LIBRARY ADDS EVENING HOURS")).check(matches(isDisplayed()))
            onView(withText("PARK TRAIL RESTORED")).check(matches(isDisplayed()))

            // Passage two: repeat the same specified actions on the same article.
            onView(withText("COMMUNITY GARDEN OPENS")).perform(click())
            onView(withText("Community garden opens")).check(matches(isDisplayed()))
            onView(withId(R.id.followUpdatesButton)).perform(click())
            onView(withText("Following updates for this article.")).check(matches(isDisplayed()))
            pressBack()
            onView(withText("COMMUNITY GARDEN OPENS")).check(matches(isDisplayed()))
            onView(withText("LIBRARY ADDS EVENING HOURS")).check(matches(isDisplayed()))
            onView(withText("PARK TRAIL RESTORED")).check(matches(isDisplayed()))

            // Passage three: repeat the same specified actions on the same article.
            onView(withText("COMMUNITY GARDEN OPENS")).perform(click())
            onView(withText("Community garden opens")).check(matches(isDisplayed()))
            onView(withId(R.id.followUpdatesButton)).perform(click())
            onView(withText("Following updates for this article.")).check(matches(isDisplayed()))
            pressBack()
            onView(withText("COMMUNITY GARDEN OPENS")).check(matches(isDisplayed()))
            onView(withText("LIBRARY ADDS EVENING HOURS")).check(matches(isDisplayed()))
            onView(withText("PARK TRAIL RESTORED")).check(matches(isDisplayed()))

            onView(withId(R.id.aboutButton)).perform(click())
            onView(withText("About News Bulletin")).check(matches(isDisplayed()))
            pressBack()
            onView(withText("COMMUNITY GARDEN OPENS")).check(matches(isDisplayed()))
            onView(withText("LIBRARY ADDS EVENING HOURS")).check(matches(isDisplayed()))
            onView(withText("PARK TRAIL RESTORED")).check(matches(isDisplayed()))

            LeakAssertions.assertNoLeaks()
        }
    }
}

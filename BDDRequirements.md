# PlateFinder — BDD Use Cases

Replace `[Plate]` with any concrete Ecuadorian plate string in tests.

---

## UC-1: Validate Plate Format

**Given** the user has typed nothing  
**When** the plate is validated  
**Then** the format is `.empty` and the search button is disabled

**Given** the user types characters that could still form a valid plate (e.g. `"AB"`, `"ABC1"`)  
**When** the plate is validated  
**Then** the format is `.partiallyValid` and the search button is disabled

**Given** the user types a complete car plate (3 letters + 4 digits, e.g. `"ABC1234"`)  
**When** the plate is validated  
**Then** the format is `.car` and the search button is enabled

**Given** the user types a complete motorcycle plate (2 letters + 3 digits + 1 letter, e.g. `"AB123A"`)  
**When** the plate is validated  
**Then** the format is `.bike` and the search button is enabled

**Given** the user types a complete special plate (2 letters + 4 digits, e.g. `"CD1234"`)  
**When** the plate is validated  
**Then** the format is `.special` and the search button is enabled

**Given** the user types characters that cannot form any valid plate (e.g. `"1ABC"`, `"ABCD"`)  
**When** the plate is validated  
**Then** the format is `.invalid` and input is rejected

---

## UC-2: Load Car Info

**Given** a complete, valid plate number  
**And** the device is online  
**When** the user triggers a search  
**Then** the app fetches HTML from the ANT endpoint with the correct query parameters  
**And** parses the HTML into a `Car` domain model  
**And** returns the `Car` on success

**Given** a complete, valid plate number  
**And** the device has no network connection  
**When** the user triggers a search  
**Then** a `.networkError` is returned  
**And** no result is delivered

**Given** a complete, valid plate number  
**And** the ANT server responds with a non-200 status code  
**When** the user triggers a search  
**Then** a `.serverError` is returned

**Given** a complete, valid plate number  
**And** the ANT server responds 200 but the HTML body has no data table  
**When** the response is parsed  
**Then** a `.noDataFound` error is returned

**Given** a complete, valid plate number  
**And** the ANT server responds 200 with a valid data table  
**When** the response is parsed  
**Then** a `Car` with all twelve fields is returned

**Given** the loader is deallocated while a request is in-flight  
**When** the response arrives  
**Then** no result is delivered (no crash, no memory leak)

---

## UC-3: View Search History

**Given** the user has previously searched one or more plate numbers  
**When** they open the history screen  
**Then** past searches are shown in reverse-chronological order (most recent first)  
**And** at most 50 items are stored

**Given** a plate was already searched  
**When** the same plate is searched again  
**Then** the existing history entry is moved to the top (no duplicates)

---

## UC-4: Re-search from History

**Given** a history item that has cached `Car` data  
**When** the user taps the item  
**Then** the cached `Car` is shown immediately — no network request is made

**Given** a history item with no cached `Car` data (previous search failed)  
**When** the user taps the item  
**Then** a fresh load is triggered for that plate number

---

## UC-5: Manage History

**Given** a list of history items  
**When** the user removes a specific item  
**Then** that item is no longer in the history

**Given** a list of history items  
**When** the user clears all history  
**Then** the history is empty

---

## UC-6: Toggle Favorite

**Given** a plate number that is not yet a favorite  
**When** the user toggles it  
**Then** it is added to favorites

**Given** a plate number that is already a favorite  
**When** the user toggles it  
**Then** it is removed from favorites

---

## UC-7: Search from Favorites

**Given** a plate number in the favorites list  
**When** the user taps it  
**Then** a load is triggered for that plate number

---

## UC-8: Siri Shortcut Search

**Given** the user invokes the "Find Plate" Siri intent with a valid plate  
**When** the intent is performed  
**Then** the app opens and a load is triggered for that plate number

**Given** the user invokes the "Find Plate" Siri intent with an invalid or incomplete plate  
**When** the intent is performed  
**Then** an error dialog is presented asking for a valid plate number

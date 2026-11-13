## [Unreleased]

- Add `Gslide::Presentation.generate_object_id` and `Gslide::Presentation::OBJECT_ID_PATTERN`, for IDs of new pages and page elements
- Require `json`, so gslide works outside Rails
- Add `ForbiddenError` (403), `NotFoundError` (404), `ServerError` (5xx) and `TimeoutError`
- Raise `Gslide::ServerError` instead of `JSON::ParserError` when an error response is not JSON, such as an HTML 502 page
- Include Google's message in `Gslide::QuotaExceededError`; treat Drive's 403 rate-limit errors as quota errors
- Retry GET requests on quota errors, 5xx and timeouts (3 attempts); POST requests are not retried, except `batch_update` on quota errors as before
- Set open (10 s) and read (60 s) timeouts
- Add `Gslide::Models::Drive#trash` (a file already gone counts as done)
- Add `Gslide::Models::Drive#rename`
- Add `Gslide::Models::Drive#copy`, e.g. a template into a folder (works with the `drive.file` scope and shared drives)

## [0.1.3] - 2026-08-19

- Add `Gslide::Presentation::PRESENTATION_ID_PATTERN` and `Gslide::Presentation.file_id_in`, so callers can validate a presentation id without repeating the pattern

## [0.1.2] - 2025-05-09

- Add `Gslide::HTTPError`, `Gslide::UnauthorizedError` and `Gslide::QuotaExceededError` #10

## [0.1.1] - 2025-04-14

- Use a regular expression for finding a presentation id from url [#8](https://github.com/lininglink/gslide/pull/8)
- Add retry logic for slide batch_update [#7](https://github.com/lininglink/gslide/pull/7)

## [0.1.0] - 2025-03-31

- Initial release

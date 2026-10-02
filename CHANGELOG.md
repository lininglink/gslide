## [Unreleased]

- Add `Gslide::Presentation.generate_object_id` and `Gslide::Presentation::OBJECT_ID_PATTERN`, for IDs of new pages and page elements

## [0.1.3] - 2026-08-19

- Add `Gslide::Presentation::PRESENTATION_ID_PATTERN` and `Gslide::Presentation.file_id_in`, so callers can validate a presentation id without repeating the pattern

## [0.1.2] - 2025-05-09

- Add `Gslide::HTTPError`, `Gslide::UnauthorizedError` and `Gslide::QuotaExceededError` #10

## [0.1.1] - 2025-04-14

- Use a regular expression for finding a presentation id from url [#8](https://github.com/lininglink/gslide/pull/8)
- Add retry logic for slide batch_update [#7](https://github.com/lininglink/gslide/pull/7)

## [0.1.0] - 2025-03-31

- Initial release

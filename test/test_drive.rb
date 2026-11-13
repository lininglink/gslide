# frozen_string_literal: true

require "test_helper"

# What Gslide::Models::Drive sends and how it reads Google's answers. No HTTP is faked:
# requests go through the gem's own response handling with a preset status and body.
class TestDrive < Minitest::Test
  Auth = Struct.new(:token)

  # Records each request and answers from preset [status, body] pairs.
  class RecordingDrive < Gslide::Models::Drive
    attr_reader :requests

    def initialize(responses)
      super(auth: Auth.new("ya29.test"))
      @responses = responses
      @requests = []
    end

    private

    def perform_request(uri, req, auth_token)
      @requests << { method: req.method, uri: uri.to_s, body: req.body && JSON.parse(req.body), token: auth_token }
      handle_response(*@responses.shift)
    end
  end

  def test_copy_into_a_folder
    drive = RecordingDrive.new([[200, '{"id": "copy1"}']])
    assert_equal "copy1", drive.copy("tmpl_1", name: "Monthly Report", folder_id: "folder-1")

    request = drive.requests.first
    assert_equal "POST", request[:method]
    assert_equal "https://www.googleapis.com/drive/v3/files/tmpl_1/copy?supportsAllDrives=true", request[:uri]
    assert_equal({ "name" => "Monthly Report", "parents" => ["folder-1"] }, request[:body])
    assert_equal "ya29.test", request[:token]
  end

  def test_copy_without_a_folder_keeps_the_original_folder
    drive = RecordingDrive.new([[200, '{"id": "copy1"}']])
    drive.copy("tmpl_1", name: "Copy")
    assert_equal({ "name" => "Copy" }, drive.requests.first[:body])
  end

  def test_rename
    drive = RecordingDrive.new([[200, '{"id": "deck1", "name": "Monthly Report"}']])
    assert_equal true, drive.rename("deck1", name: "Monthly Report")

    request = drive.requests.first
    assert_equal "PATCH", request[:method]
    assert_equal "https://www.googleapis.com/drive/v3/files/deck1?supportsAllDrives=true", request[:uri]
    assert_equal({ "name" => "Monthly Report" }, request[:body])
  end

  def test_rename_errors_are_not_retried
    drive = RecordingDrive.new([[503, "<html>Service Unavailable</html>"], [200, "{}"]])
    assert_raises(Gslide::ServerError) { drive.rename("deck1", name: "x") }
    assert_equal 1, drive.requests.size

    drive = RecordingDrive.new([])
    assert_raises(ArgumentError) { drive.rename("../x", name: "x") }
    assert_empty drive.requests
  end

  def test_errors_are_gslide_errors_and_not_retried
    drive = RecordingDrive.new([[404, '{"error": {"message": "File not found: tmpl_1."}}']])
    error = assert_raises(Gslide::NotFoundError) { drive.copy("tmpl_1", name: "x") }
    assert_equal "File not found: tmpl_1.", error.message

    drive = RecordingDrive.new([[403, '{"error": {"message": "The user does not have sufficient permissions"}}']])
    assert_raises(Gslide::ForbiddenError) { drive.copy("tmpl_1", name: "x") }

    drive = RecordingDrive.new([[503, "<html>Service Unavailable</html>"], [200, '{"id": "copy1"}']])
    assert_raises(Gslide::ServerError) { drive.copy("tmpl_1", name: "x") }
    assert_equal 1, drive.requests.size # a POST that failed may have been applied, so no retry
  end

  def test_file_ids_are_checked_before_any_request
    drive = RecordingDrive.new([])
    ["../x", "a b", "", nil, "id?x=1"].each do |bad|
      assert_raises(ArgumentError) { drive.copy(bad, name: "x") }
    end
    assert_raises(ArgumentError) { drive.copy("tmpl_1", name: "x", folder_id: "../up") }
    assert_empty drive.requests
  end
end

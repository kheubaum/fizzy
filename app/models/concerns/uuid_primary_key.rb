module UuidPrimaryKey
  extend ActiveSupport::Concern

  included do
    before_create :generate_uuid_primary_key
  end

  def self.generate
    # Base 36 UUIDs are a bit more compact; a bit less ugly
    uuid_to_base36(SecureRandom.uuid_v7)
  end

  def self.generate_fixture_uuid(label)
    # Generate deterministic UUIDv7 for fixtures that sorts by fixture ID
    # This allows .first/.last to work as expected in tests
    # Use the same CRC32 algorithm as Rails' default fixture ID generation
    # so that UUIDs sort in the same order as integer IDs
    fixture_int = Zlib.crc32("fixtures/#{label}") % (2**30 - 1)

    # Use fixture_int as second offset from a fixed base time (1 year before 2025-01-01)
    # This ensures all fixtures are in the past, and new test records are newest
    base_time = Time.utc(2024, 1, 1, 0, 0, 0)
    timestamp = base_time + fixture_int.seconds

    uuid_v7_with_timestamp(timestamp, label)
  end

  def self.uuid_v7_with_timestamp(time, seed_string)
    # Generate UUIDv7 with custom timestamp and deterministic random bits
    # Format: 48-bit timestamp_ms | 12-bit random | 4-bit version | 62-bit random

    timestamp_ms = (time.to_f * 1000).to_i

    # 48-bit timestamp (milliseconds since epoch)
    bytes = []
    bytes[0] = (timestamp_ms >> 40) & 0xff
    bytes[1] = (timestamp_ms >> 32) & 0xff
    bytes[2] = (timestamp_ms >> 24) & 0xff
    bytes[3] = (timestamp_ms >> 16) & 0xff
    bytes[4] = (timestamp_ms >> 8) & 0xff
    bytes[5] = timestamp_ms & 0xff

    # Derive deterministic "random" bits from seed_string
    hash = Digest::MD5.hexdigest(seed_string)

    # 12-bit random + 4-bit version (0111 for v7)
    rand_a = hash[0...3].to_i(16) & 0xfff
    bytes[6] = ((rand_a >> 8) & 0x0f) | 0x70  # version 7
    bytes[7] = rand_a & 0xff

    # 2-bit variant (10) + 62-bit random
    rand_b = hash[3...19].to_i(16) & ((2**62) - 1)
    bytes[8] = ((rand_b >> 56) & 0x3f) | 0x80  # variant 10
    bytes[9] = (rand_b >> 48) & 0xff
    bytes[10] = (rand_b >> 40) & 0xff
    bytes[11] = (rand_b >> 32) & 0xff
    bytes[12] = (rand_b >> 24) & 0xff
    bytes[13] = (rand_b >> 16) & 0xff
    bytes[14] = (rand_b >> 8) & 0xff
    bytes[15] = rand_b & 0xff

    # Format as UUID string
    uuid = "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % bytes
    uuid_to_base36(uuid)
  end

  def self.uuid_to_base36(uuid)
    # Convert standard UUID format to base36 (lowercase), padded to 25 chars
    uuid.delete('-').to_i(16).to_s(36).rjust(25, '0')
  end

  private

  def generate_uuid_primary_key
    return if id.present?
    self.id = UuidPrimaryKey.generate
  end
end

module Marten
  module Cache
    module Store
      # Abstract base cache store.
      abstract class Base
        DEFAULT_COMPRESS_THRESHOLD = 1024

        # Initializes a new cache store.
        #
        # The following options are supported:
        #
        # * `namespace` allows to associate a namespace value with the cache, which can be helpful if the underlying
        #   cache system is shared with other applications. Using a namespace will ensure that all they keys are
        #   properly prefixed in order to avoid collisions.
        # * `expires_in` allows to specify a default relative expiration time for cache entries.
        # * `version` allows to specify a default version value for the entries of the cache. When fetching entries, a
        #   mismatch between an entry's version and the requested version is treated like a cache miss.
        # * `compress` allows to specify whether new entries written to the cache should be compressed.
        # * `compress_threshold` allows to specify a custom compression threshold. The compression threshold determines
        #   whether cached entries are compressed: if these entries are larger than the compression threshold (which is
        #   expressed in bytes), then they will be compressed.
        def initialize(
          @namespace : String? = nil,
          @expires_in : Time::Span? = nil,
          @version : Int32? = nil,
          @compress = true,
          @compress_threshold = DEFAULT_COMPRESS_THRESHOLD
        )
        end

        # Clears the entire cache.
        abstract def clear

        # Deletes an entry associated with a given `key` from the cache. Returns `true` if an entry was deleted.
        def delete(key : String | Symbol) : Bool
          delete_entry(normalize_key(key.to_s))
        end

        # Returns `true` if an entry associated with the given `key` exists in the cache.
        #
        # The `#exists?` method allows specifying an additional `version` argument, which will be used when checking for
        # the existence of the entry. When fetching entries, a mismatch between an entry's version and the requested
        # version is treated like a cache miss.
        def exists?(key : String | Symbol, version : Int32? = nil) : Bool
          entry = read_entry(normalize_key(key.to_s))
          !entry.nil? && !entry.expired? && !entry.mismatched?(version || self.version)
        end

        # Fetches data from the cache by using the given `key`.
        #
        # If the specified `key` is associated with some data in the cache, then this data is returned. Otherwise, the
        # return value of the block will be written to the cache and returned by this method.
        #
        # It should be noted that this method supports a set of optional arguments:
        #
        # * `expires_at` allows to specify an absolute expiration time.
        # * `expires_in` allows to specify a relative expiration time.
        # * `version` allows to specify a version value for the entry to fetch/write into the cache. When fetching
        #   entries, a mismatch between an entry's version and the requested version is treated like a cache miss.
        # * `force` allows to force a cache miss, resulting in the return value of the block to be written to the cache.
        # * `race_condition_ttl` allows to specify a relative period of time during which an expired value is allowed to
        #   be returned while the new value is being generated and written to the cache. By leveraging this capability,
        #   it is possible to ensure that multiple processes that access an expired cache entry at the same time don't
        #   end up regenerating the new entry all at the same time.
        # * `compress` allows to specify whether new entries written to the cache should be compressed.
        # * `compress_threshold` allows to specify a custom compression threshold. The compression threshold determines
        #   whether cached entries are compressed: if these entries are larger than the compression threshold (which is
        #   expressed in bytes), then they will be compressed.
        def fetch(
          key : String | Symbol,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          force = false,
          race_condition_ttl : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil,
          &
        ) : String?
          normalized_key = normalize_key(key.to_s)
          entry = nil

          unless force
            entry = process_entry_expiry(read_entry(normalized_key), normalized_key, race_condition_ttl)
            entry = nil if !entry.nil? && entry.mismatched?(version || self.version)
          end

          if entry
            extract_entry_value(entry)
          else
            value = yield

            write(
              key: key,
              value: value,
              expires_at: expires_at,
              expires_in: expires_in,
              compress: compress,
              compress_threshold: compress_threshold
            )

            value
          end
        end

        # Reads data from the cache by using the given `key`.
        #
        # This method returns the entry value for the given `key` if one exists in the cache. Otherwise `nil` is
        # returned.
        #
        # The `#read` method allows specifying an additional `version` argument. When fetching entries, a mismatch
        # between an entry's version and the requested version is treated like a cache miss.
        def read(key : String | Symbol, version : Int32? = nil) : String?
          entry = read_entry(normalize_key(key.to_s))

          if !entry.nil?
            if entry.expired?
              delete_entry(key)
              nil
            elsif entry.mismatched?(version || self.version)
              nil
            else
              extract_entry_value(entry)
            end
          end
        end

        # Writes `value` into the cache by using the given `key`.
        #
        # It should be noted that this method supports a set of optional arguments:
        #
        # * `expires_at` allows to specify an absolute expiration time.
        # * `expires_in` allows to specify a relative expiration time.
        # * `version` allows to specify a version value for the entry to write into the cache. When fetching entries, a
        #   mismatch between an entry's version and the requested version is treated like a cache miss.
        # * `compress` allows to specify whether new entries written to the cache should be compressed.
        # * `compress_threshold` allows to specify a custom compression threshold. The compression threshold determines
        #   whether cached entries are compressed: if these entries are larger than the compression thresholed (which is
        #   expressed in bytes), then they will be compressed.
        def write(
          key : String | Symbol,
          value : String,
          expires_at : Time? = nil,
          expires_in : Time::Span? = nil,
          version : Int32? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
        )
          effective_expires_in = if !expires_at.nil?
                                   expires_at.to_utc - Time.utc
                                 else
                                   expires_in.nil? ? self.expires_in : expires_in
                                 end

          entry = Entry.new(value, expires_in: effective_expires_in, version: version || self.version)

          write_entry(
            key: normalize_key(key.to_s),
            entry: entry,
            expires_in: effective_expires_in,
            compress: compress,
            compress_threshold: compress_threshold
          )
        end

        private COMPRESSED_PREFIX   = "\x01"
        private UNCOMPRESSED_PREFIX = "\x00"

        private getter compress_threshold
        private getter expires_in
        private getter namespace
        private getter version

        private getter? compress

        private abstract def delete_entry(key : String) : Bool

        private abstract def read_entry(key : String) : Entry?

        private abstract def write_entry(
          key : String,
          entry : Entry,
          expires_in : Time::Span? = nil,
          compress : Bool? = nil,
          compress_threshold : Int32? = nil
        )

        private def compress(data : String) : String
          compressed_io = IO::Memory.new

          Compress::Zlib::Writer.open(compressed_io) do |zlib|
            IO.copy(IO::Memory.new(data), zlib)
          end

          compressed_data = compressed_io.rewind.gets_to_end
          compressed_io.close

          compressed_data
        end

        private def deserialize_entry(serialized_entry : String?) : Entry?
          return if serialized_entry.nil?

          packed_entry = if serialized_entry.starts_with?(COMPRESSED_PREFIX)
                           uncompress(serialized_entry.byte_slice(1..-1))
                         else
                           serialized_entry.byte_slice(1..-1)
                         end

          Entry.unpack(packed_entry)
        end

        private def extract_entry_value(entry : Entry) : String
          entry.value
        end

        private def normalize_key(key : String)
          namespace ? "#{namespace}:#{key}" : key
        end

        private def process_entry_expiry(entry : Entry?, key : String, race_condition_ttl : Time::Span?)
          if !entry.nil? && !(entry_expires_at = entry.expires_at).nil? && entry.expired?
            if !race_condition_ttl.nil? && (Time.utc.to_unix_f - entry_expires_at <= race_condition_ttl.to_f)
              # When an entry with a race condition TTL is encountered, we store the outdated entry in the cache for the
              # duration of the TTL, during which time the entry is re-calculated.
              entry.expires_at = Time.utc.to_unix_f + race_condition_ttl.to_f
              write_entry(key, entry, expires_in: race_condition_ttl * 2)
            else
              delete_entry(key)
            end

            entry = nil
          end

          entry
        end

        private def serialize_entry(entry : Entry, compress : Bool? = nil, compress_threshold : Int32? = nil)
          packed_entry = entry.pack
          effective_compress_threshold = compress_threshold.nil? ? self.compress_threshold : compress_threshold

          if (compress.nil? ? compress? : compress) && packed_entry.bytesize >= effective_compress_threshold
            COMPRESSED_PREFIX + compress(packed_entry)
          else
            UNCOMPRESSED_PREFIX + packed_entry
          end
        end

        private def uncompress(data : String) : String
          compressed_io = IO::Memory.new(data.to_slice)

          uncompressed_data = Compress::Zlib::Reader.open(compressed_io) do |zlib|
            zlib.gets_to_end
          end

          compressed_io.close

          uncompressed_data
        end
      end
    end
  end
end

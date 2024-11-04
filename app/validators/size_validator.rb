# frozen_string_literal: true

# This class provides a custom validator for ActiveModel that checks if the
# size of a given attribute exceeds a specified maximum size.
#
# ==== Examples
#
#   class MyModel < ApplicationRecord
#     validates :file_attribute, size: { max_size: 10.megabytes }
#   end
#
# ==== Parameters
#
# * +record+ - The record being validated.
# * +attribute+ - The attribute being validated.
# * +value+ - The value of the attribute being validated.
#
# ==== Options
#
# * +max_size+ - The maximum size allowed for the attribute.
#
# ==== Returns
#
# If the size of the attribute exceeds the maximum size, an error is added to
# the record's errors collection.
# The error message includes the attribute name and the maximum size allowed.
class SizeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || !value.respond_to?(:each)

    value.each do |file|
      unless file.respond_to?(:byte_size) &&
             file.byte_size > options[:max_size]
        next
      end

      message = options[:message] || "is too large. Maximum size allowed " \
        "is #{options[:max_size]} bytes."
      record.errors.add(attribute, message)
    end
  end
end

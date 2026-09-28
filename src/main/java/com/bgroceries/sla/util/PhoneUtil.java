package com.bgroceries.sla.util;

/**
 * Normalizes Cambodian phone numbers to a single canonical format (+855XXXXXXXXX)
 * so the same number entered as "012 345 678", "012345678" or "+855 12 345 678"
 * always maps to the same database row.
 */
public final class PhoneUtil {

    private PhoneUtil() {
    }

    public static String normalize(String rawPhone) {
        if (rawPhone == null) {
            return null;
        }

        String cleaned = rawPhone.trim().replaceAll("[^0-9+]", "");

        if (cleaned.startsWith("+855")) {
            return cleaned;
        }
        if (cleaned.startsWith("855")) {
            return "+" + cleaned;
        }
        if (cleaned.startsWith("0")) {
            return "+855" + cleaned.substring(1);
        }
        return "+855" + cleaned;
    }
}

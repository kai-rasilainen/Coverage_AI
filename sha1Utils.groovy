// sha1Utils.groovy
/**
 * Calculates the SHA-1 hash of a given string input.
 * This closure is returned when the script is loaded.
 * * @param input The string to hash (e.g., a test case body).
 * @return The 40-character hexadecimal SHA-1 hash string.
 */
{ input ->
    if (input == null || input.isEmpty()) return ""
    def md = java.security.MessageDigest.getInstance("SHA-1")
    md.update(input.getBytes("UTF-8"))
    // Converts the digest to a 40-character hex string
    return new BigInteger(1, md.digest()).toString(16).padLeft(40, '0')
}

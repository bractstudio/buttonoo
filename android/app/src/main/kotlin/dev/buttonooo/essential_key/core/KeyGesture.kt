package dev.buttonooo.essential_key.core

enum class KeyGesture(val key: String) {
    SINGLE_PRESS("single"),
    DOUBLE_PRESS("double"),
    TRIPLE_PRESS("triple"),
    QUADRUPLE_PRESS("quadruple"),
    LONG_PRESS("long");

    companion object {
        fun fromKey(key: String): KeyGesture? = values().firstOrNull { it.key == key }
    }
}

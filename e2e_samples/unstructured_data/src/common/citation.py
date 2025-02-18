from dataclasses import dataclass, field
from typing import Optional


@dataclass
class MatchResult:
    ratio: float
    text: str


@dataclass
class Citation:
    document_name: str
    excerpt: Optional[str] = field(default=None)
    explanation: Optional[str] = field(default=None)
    raw: Optional[str] = field(default=None)


@dataclass
class ValidatedCitation(Citation):
    match: Optional[MatchResult] = field(default=None)


@dataclass
class ValidCitation(ValidatedCitation):
    status: str = "Valid"


@dataclass
class InvalidCitation(ValidatedCitation):
    error: Optional[str] = field(default=None)
    status: str = "Invalid"
